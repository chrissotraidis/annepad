#!/usr/bin/env swift

import AVFoundation
import CoreVideo
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: swift scripts/analyze-simulator-video.swift VIDEO.mov\n", stderr)
    exit(2)
}

let asset = AVURLAsset(url: URL(fileURLWithPath: CommandLine.arguments[1]))
let tracks = try await asset.loadTracks(withMediaType: .video)
guard let track = tracks.first else {
    fputs("video has no image track\n", stderr)
    exit(1)
}

let reader = try AVAssetReader(asset: asset)
let output = AVAssetReaderTrackOutput(
    track: track,
    outputSettings: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    ]
)
output.alwaysCopiesSampleData = false
reader.add(output)
guard reader.startReading() else {
    fputs("could not start video reader\n", stderr)
    exit(1)
}

let sampleStep = 64
let unchangedThreshold = 0.10
let minimumUnchangedSeconds = 0.25

var previous: [UInt8]?
var frameCount = 0
var firstPTS = 0.0
var lastPTS = 0.0
var unchangedStart: Double?
var unchangedRuns: [(start: Double, end: Double, duration: Double)] = []
var differences: [Double] = []

while let sample = output.copyNextSampleBuffer(),
      let pixel = CMSampleBufferGetImageBuffer(sample) {
    let pts = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sample))
    if frameCount == 0 { firstPTS = pts }
    lastPTS = pts

    CVPixelBufferLockBaseAddress(pixel, .readOnly)
    let width = CVPixelBufferGetWidth(pixel)
    let height = CVPixelBufferGetHeight(pixel)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixel)
    let base = CVPixelBufferGetBaseAddress(pixel)!.assumingMemoryBound(to: UInt8.self)
    var signature: [UInt8] = []
    signature.reserveCapacity(
        ((width + sampleStep - 1) / sampleStep) *
        ((height + sampleStep - 1) / sampleStep) * 3
    )
    for y in Swift.stride(from: 0, to: height, by: sampleStep) {
        let row = base.advanced(by: y * bytesPerRow)
        for x in Swift.stride(from: 0, to: width, by: sampleStep) {
            let component = row.advanced(by: x * 4)
            signature.append(component[0])
            signature.append(component[1])
            signature.append(component[2])
        }
    }
    CVPixelBufferUnlockBaseAddress(pixel, .readOnly)

    if let prior = previous {
        var sum = 0
        for index in signature.indices {
            sum += abs(Int(signature[index]) - Int(prior[index]))
        }
        let difference = Double(sum) / Double(signature.count)
        differences.append(difference)
        if difference < unchangedThreshold {
            if unchangedStart == nil { unchangedStart = pts }
        } else if let start = unchangedStart {
            let duration = pts - start
            if duration >= minimumUnchangedSeconds {
                unchangedRuns.append((start, pts, duration))
            }
            unchangedStart = nil
        }
    }
    previous = signature
    frameCount += 1
}

if let start = unchangedStart {
    let duration = lastPTS - start
    if duration >= minimumUnchangedSeconds {
        unchangedRuns.append((start, lastPTS, duration))
    }
}

guard reader.status == .completed, frameCount > 1 else {
    fputs("video decode did not complete: \(String(describing: reader.error))\n", stderr)
    exit(1)
}

let duration = lastPTS - firstPTS
let sortedDifferences = differences.sorted()
func percentile(_ fraction: Double) -> Double {
    sortedDifferences[Int(Double(sortedDifferences.count - 1) * fraction)]
}

print(String(
    format: "frames=%d duration=%.3f nominal_fps=%.3f",
    frameCount, duration, Double(frameCount) / duration
))
print(String(
    format: "sampled_pixel_difference p10=%.3f median=%.3f p90=%.3f",
    percentile(0.1), percentile(0.5), percentile(0.9)
))
print(String(
    format: "near_unchanged_runs threshold=%.2f minimum=%.2fs count=%d",
    unchangedThreshold, minimumUnchangedSeconds, unchangedRuns.count
))
for run in unchangedRuns {
    print(String(
        format: "unchanged start=%.3f end=%.3f duration=%.3f",
        run.start, run.end, run.duration
    ))
}
