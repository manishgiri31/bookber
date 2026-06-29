import 'package:flutter/widgets.dart';

// Phosphor icon fonts bundled in assets/fonts/ — no package needed.
// Regular: fontFamily 'Phosphor'   Fill: fontFamily 'PhosphorFill'
const _r = 'Phosphor';
const _f = 'PhosphorFill';

abstract final class AppIcons {
  // Navigation
  static const home               = IconData(0xe2c2, fontFamily: _r);
  static const homeActive         = IconData(0xe2c2, fontFamily: _f);
  static const shops              = IconData(0xe470, fontFamily: _r);
  static const shopsActive        = IconData(0xe470, fontFamily: _f);
  static const bookings           = IconData(0xe10a, fontFamily: _r);
  static const bookingsActive     = IconData(0xe10a, fontFamily: _f);
  static const profile            = IconData(0xe4c2, fontFamily: _r);
  static const profileActive      = IconData(0xe4c2, fontFamily: _f);

  // Common UI
  static const search             = IconData(0xe30c, fontFamily: _r);
  static const filter             = IconData(0xe434, fontFamily: _r);
  static const close              = IconData(0xe4f6, fontFamily: _r);
  static const closeFill          = IconData(0xe4f6, fontFamily: _f);
  static const arrowBack          = IconData(0xe058, fontFamily: _r);
  static const arrowForward       = IconData(0xe06c, fontFamily: _r);
  static const arrowForwardSmall  = IconData(0xe13a, fontFamily: _r);
  static const arrowDown          = IconData(0xe136, fontFamily: _r);
  static const arrowUp            = IconData(0xe13c, fontFamily: _r);
  static const arrowDownLarge     = IconData(0xe03e, fontFamily: _r);
  static const arrowUpLarge       = IconData(0xe08e, fontFamily: _r);
  static const check              = IconData(0xe182, fontFamily: _r);
  static const checkCircle        = IconData(0xe184, fontFamily: _r);
  static const checkCircleFill    = IconData(0xe184, fontFamily: _f);
  static const add                = IconData(0xe3d4, fontFamily: _r);
  static const remove             = IconData(0xe32a, fontFamily: _r);
  static const addCircle          = IconData(0xe3d6, fontFamily: _r);
  static const removeCircle       = IconData(0xe32c, fontFamily: _r);
  static const edit               = IconData(0xe3b4, fontFamily: _r);
  static const deleteIcon         = IconData(0xe4a6, fontFamily: _r);
  static const deleteFill         = IconData(0xe4a6, fontFamily: _f);
  static const copy               = IconData(0xe1ca, fontFamily: _r);
  static const save               = IconData(0xe248, fontFamily: _r);
  static const more               = IconData(0xe208, fontFamily: _r);
  static const share              = IconData(0xe408, fontFamily: _r);
  static const refresh            = IconData(0xe036, fontFamily: _r);
  static const replay             = IconData(0xe038, fontFamily: _r);
  static const send               = IconData(0xe398, fontFamily: _r);
  static const image              = IconData(0xe2ca, fontFamily: _r);
  static const camera             = IconData(0xe10e, fontFamily: _r);
  static const visibility         = IconData(0xe220, fontFamily: _r);
  static const visibilityOff      = IconData(0xe224, fontFamily: _r);
  static const swap               = IconData(0xe0a0, fontFamily: _r);
  static const clear              = IconData(0xe4f6, fontFamily: _r);

  // Booking / Services
  static const scissors           = IconData(0xeae0, fontFamily: _r);
  static const scissorsFill       = IconData(0xeae0, fontFamily: _f);
  static const queue              = IconData(0xe6ac, fontFamily: _r);
  static const queueFill          = IconData(0xe6ac, fontFamily: _f);
  static const schedule           = IconData(0xe19a, fontFamily: _r);
  static const scheduleFill       = IconData(0xe19a, fontFamily: _f);
  static const timer              = IconData(0xe492, fontFamily: _r);
  static const timerFill          = IconData(0xe492, fontFamily: _f);
  static const timerOff           = IconData(0xe492, fontFamily: _r);
  static const calendar           = IconData(0xe10a, fontFamily: _r);
  static const calendarFill       = IconData(0xe10a, fontFamily: _f);
  static const calendarMonth      = IconData(0xe7b4, fontFamily: _r);
  static const eventBusy          = IconData(0xe10c, fontFamily: _r);
  static const receipt            = IconData(0xe3ec, fontFamily: _r);
  static const receiptFill        = IconData(0xe3ec, fontFamily: _f);
  static const payment            = IconData(0xe1d2, fontFamily: _r);
  static const paymentFill        = IconData(0xe1d2, fontFamily: _f);
  static const chair              = IconData(0xe012, fontFamily: _r);
  static const chairFill          = IconData(0xe012, fontFamily: _f);
  static const pending            = IconData(0xe2b4, fontFamily: _r);
  static const cancel             = IconData(0xe4f8, fontFamily: _r);
  static const cancelFill         = IconData(0xe4f8, fontFamily: _f);
  static const skipNext           = IconData(0xe5a6, fontFamily: _r);
  static const pause              = IconData(0xe39e, fontFamily: _r);
  static const bolt               = IconData(0xe2de, fontFamily: _r);
  static const boltFill           = IconData(0xe2de, fontFamily: _f);
  static const shuffle            = IconData(0xe422, fontFamily: _r);
  static const accessTime         = IconData(0xe19c, fontFamily: _r);

  // Star / Rating
  static const star               = IconData(0xe46a, fontFamily: _r);
  static const starFill           = IconData(0xe46a, fontFamily: _f);

  // Location
  static const locationOn         = IconData(0xe316, fontFamily: _r);
  static const locationOnFill     = IconData(0xe316, fontFamily: _f);
  static const locationOff        = IconData(0xe316, fontFamily: _r);
  static const nearMe             = IconData(0xeade, fontFamily: _r);
  static const nearMeDisabled     = IconData(0xeade, fontFamily: _r);
  static const myLocation         = IconData(0xe1d6, fontFamily: _r);
  static const map                = IconData(0xe31a, fontFamily: _r);
  static const mapFill            = IconData(0xe31a, fontFamily: _f);
  static const directions         = IconData(0xe39c, fontFamily: _r);
  static const walk               = IconData(0xe73a, fontFamily: _r);
  static const locationCity       = IconData(0xe102, fontFamily: _r);

  // Notifications & Alerts
  static const bell               = IconData(0xe0ce, fontFamily: _r);
  static const bellFill           = IconData(0xe0ce, fontFamily: _f);
  static const bellActive         = IconData(0xe5e8, fontFamily: _f);
  static const warning            = IconData(0xe4e0, fontFamily: _r);
  static const warningFill        = IconData(0xe4e0, fontFamily: _f);
  static const error              = IconData(0xe4f8, fontFamily: _r);
  static const info               = IconData(0xe2ce, fontFamily: _r);
  static const infoFill           = IconData(0xe2ce, fontFamily: _f);
  static const cloudOff           = IconData(0xe1b6, fontFamily: _r);

  // Auth / Security
  static const lock               = IconData(0xe2fa, fontFamily: _r);
  static const lockFill           = IconData(0xe2fa, fontFamily: _f);
  static const fingerprint        = IconData(0xe23e, fontFamily: _r);
  static const privacy            = IconData(0xe40c, fontFamily: _r);
  static const privacyFill        = IconData(0xe40c, fontFamily: _f);

  // Profile / Account
  static const person             = IconData(0xe4c2, fontFamily: _r);
  static const personFill         = IconData(0xe4c2, fontFamily: _f);
  static const personAdd          = IconData(0xe4d0, fontFamily: _r);
  static const personOff          = IconData(0xe4ce, fontFamily: _r);
  static const people             = IconData(0xe4d6, fontFamily: _r);
  static const peopleFill         = IconData(0xe4d6, fontFamily: _f);
  static const groups             = IconData(0xe68e, fontFamily: _r);
  static const mail               = IconData(0xe214, fontFamily: _r);
  static const mailFill           = IconData(0xe214, fontFamily: _f);
  static const phone              = IconData(0xe3b8, fontFamily: _r);
  static const phoneFill          = IconData(0xe3b8, fontFamily: _f);
  static const sms                = IconData(0xe17a, fontFamily: _r);
  static const logout             = IconData(0xe42a, fontFamily: _r);

  // Settings
  static const darkMode           = IconData(0xe330, fontFamily: _r);
  static const lightMode          = IconData(0xe472, fontFamily: _r);
  static const brightnessAuto     = IconData(0xe474, fontFamily: _r);
  static const language           = IconData(0xe288, fontFamily: _r);
  static const languageFill       = IconData(0xe288, fontFamily: _f);
  static const toggleOn           = IconData(0xe676, fontFamily: _r);

  // Shop / Business
  static const store              = IconData(0xe470, fontFamily: _r);
  static const storeFill          = IconData(0xe470, fontFamily: _f);
  static const storeAlt           = IconData(0xe102, fontFamily: _r);
  static const parking            = IconData(0xecb2, fontFamily: _r);
  static const public             = IconData(0xe288, fontFamily: _r);
  static const dataUsage          = IconData(0xe154, fontFamily: _r);

  // Rewards / Gamification
  static const wallet             = IconData(0xe68a, fontFamily: _r);
  static const walletFill         = IconData(0xe68a, fontFamily: _f);
  static const loyalty            = IconData(0xe320, fontFamily: _r);
  static const loyaltyFill        = IconData(0xe320, fontFamily: _f);
  static const trophy             = IconData(0xe67e, fontFamily: _r);
  static const trophyFill         = IconData(0xe67e, fontFamily: _f);
  static const gift               = IconData(0xe276, fontFamily: _r);
  static const giftFill           = IconData(0xe276, fontFamily: _f);
  static const ticket             = IconData(0xe490, fontFamily: _r);
  static const ticketFill         = IconData(0xe490, fontFamily: _f);
  static const redeem             = IconData(0xe490, fontFamily: _r);
  static const diamond            = IconData(0xe1ec, fontFamily: _r);
  static const diamondFill        = IconData(0xe1ec, fontFamily: _f);
  static const premium            = IconData(0xe614, fontFamily: _r);
  static const premiumFill        = IconData(0xe614, fontFamily: _f);
  static const localOffer         = IconData(0xe478, fontFamily: _r);
  static const localOfferFill     = IconData(0xe478, fontFamily: _f);
  static const bookmark           = IconData(0xe0e8, fontFamily: _r);
  static const bookmarkFill       = IconData(0xe0e8, fontFamily: _f);
  static const favorite           = IconData(0xe2a8, fontFamily: _r);
  static const favoriteFill       = IconData(0xe2a8, fontFamily: _f);
  static const flag               = IconData(0xe244, fontFamily: _r);
  static const flagFill           = IconData(0xe244, fontFamily: _f);
  static const labelOutline       = IconData(0xe478, fontFamily: _r);
  static const qrCode             = IconData(0xe3e6, fontFamily: _r);

  // Services / Categories
  static const spa                = IconData(0xe2da, fontFamily: _r);
  static const selfImprovement    = IconData(0xe92a, fontFamily: _r);
  static const childCare          = IconData(0xe774, fontFamily: _r);
  static const face               = IconData(0xe436, fontFamily: _r);
  static const palette            = IconData(0xe6c8, fontFamily: _r);
  static const paletteOutline     = IconData(0xe6c8, fontFamily: _r);
  static const waterDrop          = IconData(0xe210, fontFamily: _r);
  static const autoFix            = IconData(0xe6b6, fontFamily: _r);
  static const fire               = IconData(0xe242, fontFamily: _f);
  static const wash               = IconData(0xe210, fontFamily: _r);
  static const wc                 = IconData(0xe79a, fontFamily: _r);

  // Dashboard / Analytics
  static const dashboard          = IconData(0xe464, fontFamily: _r);
  static const dashboardFill      = IconData(0xe464, fontFamily: _f);
  static const analytics          = IconData(0xe150, fontFamily: _r);
  static const analyticsFill      = IconData(0xe150, fontFamily: _f);
  static const speed              = IconData(0xe628, fontFamily: _r);
  static const speedFill          = IconData(0xe628, fontFamily: _f);

  // History
  static const history            = IconData(0xe1a0, fontFamily: _r);
  static const explore            = IconData(0xea0e, fontFamily: _r);

  // Support
  static const helpOutline        = IconData(0xe3e8, fontFamily: _r);
  static const support            = IconData(0xe584, fontFamily: _r);
  static const chat               = IconData(0xe168, fontFamily: _r);
  static const article            = IconData(0xe0a8, fontFamily: _r);
  static const circle             = IconData(0xe18a, fontFamily: _r);
  static const circleFill         = IconData(0xe18a, fontFamily: _f);
  static const radioChecked       = IconData(0xeb08, fontFamily: _f);

  // Connectivity
  static const wifi               = IconData(0xe4ea, fontFamily: _r);
  static const wifiOff            = IconData(0xe4f4, fontFamily: _r);

  // Misc
  static const addPhoto           = IconData(0xe2cc, fontFamily: _r);
  static const accessible         = IconData(0xe4e8, fontFamily: _r);
  static const acUnit             = IconData(0xe5aa, fontFamily: _r);
  static const childFriendly      = IconData(0xe774, fontFamily: _r);
  static const localConvenienceStore = IconData(0xe470, fontFamily: _r);
  static const colorLens          = IconData(0xe6c8, fontFamily: _r);
  static const personOutline      = IconData(0xe4c2, fontFamily: _r);
  static const moneyRounded       = IconData(0xe588, fontFamily: _r);
  static const currencyRupee      = IconData(0xe558, fontFamily: _r);
  static const repeat             = IconData(0xe036, fontFamily: _r);
  static const description        = IconData(0xe0a8, fontFamily: _r);
  static const barChart           = IconData(0xe150, fontFamily: _r);
  static const notifications      = IconData(0xe0ce, fontFamily: _r);
}
