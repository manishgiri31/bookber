import 'package:phosphor_flutter/phosphor_flutter.dart';

abstract final class AppIcons {
  // Navigation
  static const home = PhosphorIconsRegular.house;
  static const homeActive = PhosphorIconsFill.house;
  static const shops = PhosphorIconsRegular.storefront;
  static const shopsActive = PhosphorIconsFill.storefront;
  static const bookings = PhosphorIconsRegular.calendarBlank;
  static const bookingsActive = PhosphorIconsFill.calendarBlank;
  static const profile = PhosphorIconsRegular.user;
  static const profileActive = PhosphorIconsFill.user;

  // Common UI
  static const search = PhosphorIconsRegular.magnifyingGlass;
  static const filter = PhosphorIconsRegular.slidersHorizontal;
  static const close = PhosphorIconsRegular.x;
  static const closeFill = PhosphorIconsFill.x;
  static const arrowBack = PhosphorIconsRegular.arrowLeft;
  static const arrowForward = PhosphorIconsRegular.arrowRight;
  static const arrowForwardSmall = PhosphorIconsRegular.caretRight;
  static const arrowDown = PhosphorIconsRegular.caretDown;
  static const arrowUp = PhosphorIconsRegular.caretUp;
  static const arrowDownLarge = PhosphorIconsRegular.arrowDown;
  static const arrowUpLarge = PhosphorIconsRegular.arrowUp;
  static const check = PhosphorIconsRegular.check;
  static const checkCircle = PhosphorIconsRegular.checkCircle;
  static const checkCircleFill = PhosphorIconsFill.checkCircle;
  static const add = PhosphorIconsRegular.plus;
  static const remove = PhosphorIconsRegular.minus;
  static const addCircle = PhosphorIconsRegular.plusCircle;
  static const removeCircle = PhosphorIconsRegular.minusCircle;
  static const edit = PhosphorIconsRegular.pencilSimple;
  static const deleteIcon = PhosphorIconsRegular.trash;
  static const deleteFill = PhosphorIconsFill.trash;
  static const copy = PhosphorIconsRegular.copy;
  static const save = PhosphorIconsRegular.floppyDisk;
  static const more = PhosphorIconsRegular.dotsThreeVertical;
  static const share = PhosphorIconsRegular.shareNetwork;
  static const refresh = PhosphorIconsRegular.arrowClockwise;
  static const replay = PhosphorIconsRegular.arrowCounterClockwise;
  static const send = PhosphorIconsRegular.paperPlaneTilt;
  static const image = PhosphorIconsRegular.image;
  static const camera = PhosphorIconsRegular.camera;
  static const visibility = PhosphorIconsRegular.eye;
  static const visibilityOff = PhosphorIconsRegular.eyeSlash;
  static const swap = PhosphorIconsRegular.arrowsLeftRight;
  static const clear = PhosphorIconsRegular.x;

  // Booking / Services
  static const scissors = PhosphorIconsRegular.scissors;
  static const scissorsFill = PhosphorIconsFill.scissors;
  static const queue = PhosphorIconsRegular.queue;
  static const queueFill = PhosphorIconsFill.queue;
  static const schedule = PhosphorIconsRegular.clock;
  static const scheduleFill = PhosphorIconsFill.clock;
  static const timer = PhosphorIconsRegular.timer;
  static const timerFill = PhosphorIconsFill.timer;
  static const timerOff = PhosphorIconsRegular.timer;
  static const calendar = PhosphorIconsRegular.calendarBlank;
  static const calendarFill = PhosphorIconsFill.calendarBlank;
  static const calendarMonth = PhosphorIconsRegular.calendarDots;
  static const eventBusy = PhosphorIconsRegular.calendarX;
  static const receipt = PhosphorIconsRegular.receipt;
  static const receiptFill = PhosphorIconsFill.receipt;
  static const payment = PhosphorIconsRegular.creditCard;
  static const paymentFill = PhosphorIconsFill.creditCard;
  static const chair = PhosphorIconsRegular.armchair;
  static const chairFill = PhosphorIconsFill.armchair;
  static const pending = PhosphorIconsRegular.hourglassHigh;
  static const cancel = PhosphorIconsRegular.xCircle;
  static const cancelFill = PhosphorIconsFill.xCircle;
  static const skipNext = PhosphorIconsRegular.skipForward;
  static const pause = PhosphorIconsRegular.pause;
  static const bolt = PhosphorIconsRegular.lightning;
  static const boltFill = PhosphorIconsFill.lightning;
  static const shuffle = PhosphorIconsRegular.shuffle;
  static const accessTime = PhosphorIconsRegular.clockAfternoon;

  // Star / Rating
  static const star = PhosphorIconsRegular.star;
  static const starFill = PhosphorIconsFill.star;

  // Location
  static const locationOn = PhosphorIconsRegular.mapPin;
  static const locationOnFill = PhosphorIconsFill.mapPin;
  static const locationOff = PhosphorIconsRegular.mapPin;
  static const nearMe = PhosphorIconsRegular.navigationArrow;
  static const nearMeDisabled = PhosphorIconsRegular.navigationArrow;
  static const myLocation = PhosphorIconsRegular.crosshair;
  static const map = PhosphorIconsRegular.mapTrifold;
  static const mapFill = PhosphorIconsFill.mapTrifold;
  static const directions = PhosphorIconsRegular.path;
  static const walk = PhosphorIconsRegular.personSimpleWalk;
  static const locationCity = PhosphorIconsRegular.buildings;

  // Notifications & Alerts
  static const bell = PhosphorIconsRegular.bell;
  static const bellFill = PhosphorIconsFill.bell;
  static const bellActive = PhosphorIconsFill.bellRinging;
  static const warning = PhosphorIconsRegular.warning;
  static const warningFill = PhosphorIconsFill.warning;
  static const error = PhosphorIconsRegular.xCircle;
  static const info = PhosphorIconsRegular.info;
  static const infoFill = PhosphorIconsFill.info;
  static const cloudOff = PhosphorIconsRegular.cloudSlash;

  // Auth / Security
  static const lock = PhosphorIconsRegular.lock;
  static const lockFill = PhosphorIconsFill.lock;
  static const fingerprint = PhosphorIconsRegular.fingerprint;
  static const privacy = PhosphorIconsRegular.shieldCheck;
  static const privacyFill = PhosphorIconsFill.shieldCheck;

  // Profile / Account
  static const person = PhosphorIconsRegular.user;
  static const personFill = PhosphorIconsFill.user;
  static const personAdd = PhosphorIconsRegular.userPlus;
  static const personOff = PhosphorIconsRegular.userMinus;
  static const people = PhosphorIconsRegular.users;
  static const peopleFill = PhosphorIconsFill.users;
  static const groups = PhosphorIconsRegular.usersThree;
  static const mail = PhosphorIconsRegular.envelope;
  static const mailFill = PhosphorIconsFill.envelope;
  static const phone = PhosphorIconsRegular.phone;
  static const phoneFill = PhosphorIconsFill.phone;
  static const sms = PhosphorIconsRegular.chatText;
  static const logout = PhosphorIconsRegular.signOut;

  // Settings
  static const darkMode = PhosphorIconsRegular.moon;
  static const lightMode = PhosphorIconsRegular.sun;
  static const brightnessAuto = PhosphorIconsRegular.sunDim;
  static const language = PhosphorIconsRegular.globe;
  static const languageFill = PhosphorIconsFill.globe;
  static const toggleOn = PhosphorIconsRegular.toggleRight;

  // Shop / Business
  static const store = PhosphorIconsRegular.storefront;
  static const storeFill = PhosphorIconsFill.storefront;
  static const storeAlt = PhosphorIconsRegular.buildings;
  static const parking = PhosphorIconsRegular.park;
  static const public = PhosphorIconsRegular.globe;
  static const dataUsage = PhosphorIconsRegular.chartLine;

  // Rewards / Gamification
  static const wallet = PhosphorIconsRegular.wallet;
  static const walletFill = PhosphorIconsFill.wallet;
  static const loyalty = PhosphorIconsRegular.medal;
  static const loyaltyFill = PhosphorIconsFill.medal;
  static const trophy = PhosphorIconsRegular.trophy;
  static const trophyFill = PhosphorIconsFill.trophy;
  static const gift = PhosphorIconsRegular.gift;
  static const giftFill = PhosphorIconsFill.gift;
  static const ticket = PhosphorIconsRegular.ticket;
  static const ticketFill = PhosphorIconsFill.ticket;
  static const redeem = PhosphorIconsRegular.ticket;
  static const diamond = PhosphorIconsRegular.diamond;
  static const diamondFill = PhosphorIconsFill.diamond;
  static const premium = PhosphorIconsRegular.crown;
  static const premiumFill = PhosphorIconsFill.crown;
  static const localOffer = PhosphorIconsRegular.tag;
  static const localOfferFill = PhosphorIconsFill.tag;
  static const bookmark = PhosphorIconsRegular.bookmark;
  static const bookmarkFill = PhosphorIconsFill.bookmark;
  static const favorite = PhosphorIconsRegular.heart;
  static const favoriteFill = PhosphorIconsFill.heart;
  static const flag = PhosphorIconsRegular.flag;
  static const flagFill = PhosphorIconsFill.flag;
  static const labelOutline = PhosphorIconsRegular.tag;
  static const qrCode = PhosphorIconsRegular.qrCode;

  // Services / Categories
  static const spa = PhosphorIconsRegular.leaf;
  static const selfImprovement = PhosphorIconsRegular.yinYang;
  static const childCare = PhosphorIconsRegular.baby;
  static const face = PhosphorIconsRegular.smiley;
  static const palette = PhosphorIconsRegular.palette;
  static const paletteOutline = PhosphorIconsRegular.palette;
  static const waterDrop = PhosphorIconsRegular.drop;
  static const autoFix = PhosphorIconsRegular.magicWand;
  static const fire = PhosphorIconsFill.fire;
  static const wash = PhosphorIconsRegular.drop;
  static const wc = PhosphorIconsRegular.toilet;

  // Dashboard / Analytics
  static const dashboard = PhosphorIconsRegular.squaresFour;
  static const dashboardFill = PhosphorIconsFill.squaresFour;
  static const analytics = PhosphorIconsRegular.chartBar;
  static const analyticsFill = PhosphorIconsFill.chartBar;
  static const speed = PhosphorIconsRegular.gauge;
  static const speedFill = PhosphorIconsFill.gauge;

  // History
  static const history = PhosphorIconsRegular.clockCounterClockwise;
  static const explore = PhosphorIconsRegular.compassTool;

  // Support
  static const helpOutline = PhosphorIconsRegular.question;
  static const support = PhosphorIconsRegular.headset;
  static const chat = PhosphorIconsRegular.chatCircle;
  static const article = PhosphorIconsRegular.article;
  static const circle = PhosphorIconsRegular.circle;
  static const circleFill = PhosphorIconsFill.circle;
  static const radioChecked = PhosphorIconsFill.radioButton;

  // Connectivity
  static const wifi = PhosphorIconsRegular.wifiHigh;
  static const wifiOff = PhosphorIconsRegular.wifiX;

  // Misc
  static const addPhoto = PhosphorIconsRegular.imageSquare;
  static const accessible = PhosphorIconsRegular.wheelchair;
  static const acUnit = PhosphorIconsRegular.snowflake;
  static const childFriendly = PhosphorIconsRegular.baby;
  static const localConvenienceStore = PhosphorIconsRegular.storefront;
  static const colorLens = PhosphorIconsRegular.palette;
  static const personOutline = PhosphorIconsRegular.user;
  static const moneyRounded = PhosphorIconsRegular.money;
  static const currencyRupee = PhosphorIconsRegular.currencyInr;
  static const repeat = PhosphorIconsRegular.arrowClockwise;
  static const description = PhosphorIconsRegular.article;
  static const barChart = PhosphorIconsRegular.chartBar;
  static const notifications = PhosphorIconsRegular.bell;
}
