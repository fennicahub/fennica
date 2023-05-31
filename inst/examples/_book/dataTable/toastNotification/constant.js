const ACCEPTED_TOAST_POSITIONS = {
  "top-left": "top-left",
  "top-right": "top-right",
  "bottom-left": "bottom-left",
  "bottom-right": "bottom-right",
  "top-center": "top-center",
  "bottom-center": "bottom-center",
};

const ACCEPTED_TOAST_TYPES = {
  info: "info",
  warning: "warning",
  error: "error",
  success: "success",
  default: "default",
};

const toastTypeColorCodeMap = {
  default: "#2196F3",
  info: "#2196F3",
  warning: "#FFDA6B",
  success: "#32BEA6",
  error: "#FF3055",
};

const DEFAULT_CONFIG = {
  autoClose: 5000,
  canCloseOnClick: true,
  darkMode: false,
  onClose: () => {},
  position: ACCEPTED_TOAST_POSITIONS["top-right"],
  showProgressBar: true,
  pauseOnHover: true,
  pauseOnFocusLoss: true,
  playNotificationSound: false,
  toastContent: {
    title: "Yay! My first 🍞",
    message: "This is awesome!!!",
    type: ACCEPTED_TOAST_TYPES.default,
  },
};

const AUDIO_ASSETS_PATH = "toastNotification/assets/notification_sounds";
const IMAGE_ASSETS_PATH = "toastNotification/assets/images";
const ASSET_TYPE_TO_USE = "gif";

export {
  ACCEPTED_TOAST_POSITIONS,
  ACCEPTED_TOAST_TYPES,
  toastTypeColorCodeMap,
  DEFAULT_CONFIG,
  AUDIO_ASSETS_PATH,
  IMAGE_ASSETS_PATH,
  ASSET_TYPE_TO_USE,
};
