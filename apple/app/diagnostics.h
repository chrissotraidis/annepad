#pragma once
#import <UIKit/UIKit.h>

void annepad_start_diagnostics(NSURL* root);
void annepad_diagnostic_event(const char* event);
void annepad_share_diagnostics(UIViewController* presenter);
