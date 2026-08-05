# Install the AnnePad developer preview

AnnePad's downloadable IPA is unsigned and ROM-free. It is not an App Store,
TestFlight, or AltStore PAL package. You need a Mac or Windows PC running
[AltServer](https://altstore.io/) so AltStore Classic can re-sign the app with
your own Apple ID.

## Install

1. Install AltServer on your Mac or Windows PC and use it to install AltStore
   Classic on your iPhone or iPad.
2. Download `AnnePad-0.1.0-preview.1-unsigned.ipa` from the [GitHub
   release](https://github.com/chrissotraidis/annepad/releases/tag/v0.1.0-preview.1).
3. Open the IPA with AltStore Classic, or use **My Apps → +** and select it.
4. Keep the device connected to the same computer/network while AltServer
   signs and installs the app.
5. Launch AnnePad and choose your own legally obtained Pokémon Stadium (US) 1.0
   ROM through Files.

Free Apple IDs generally require periodic re-signing. Installation, refresh,
and device-registration errors occur before AnnePad launches and should be
checked against AltStore's current documentation.

## Important boundaries

- The IPA contains no Pokémon Stadium ROM, save, extracted Nintendo asset,
  certificate, or provisioning profile.
- Only the exact supported US 1.0 ROM revision is accepted.
- Do not request or share game downloads through this project.
- Installing a new build in place preserves the app container. Uninstalling the
  app removes its imported ROM and saves unless you back them up first.
