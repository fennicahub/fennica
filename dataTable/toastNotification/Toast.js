import {
  ACCEPTED_TOAST_TYPES,
  DEFAULT_CONFIG,
  ACCEPTED_TOAST_POSITIONS,
  toastTypeColorCodeMap,
  AUDIO_ASSETS_PATH,
} from "./constant.js";
import { createToastContainer, getToastContent } from "./utils.js";

export default class Toast {
  #toastElement;
  #toastType = ACCEPTED_TOAST_TYPES.default;
  #autoCloseInterval;
  #removeBindedToast;
  #autoCloseTime; // store the autoclose value for progress bar calculations.
  #visibleSince; // prop to handle progress bar calculations.
  #progressInterval;
  #isPaused = false;
  #resume;
  #pause;
  #visibilityChange;
  #shouldResume;
  #shouldPlaySound;

  // Ref for options: https://fkhadra.github.io/react-toastify/api/toast/
  constructor(options) {
    const IS_DARK = options.darkMode || false;

    // Brewing up the toast notif element.
    this.#toastElement = document.createElement("div");
    this.#toastElement.classList.add("toast");
    this.#toastElement.style.setProperty(
      "--toast_background",
      IS_DARK ? "black" : "white"
    );
    this.#toastElement.style.setProperty(
      "--toast_title_color",
      IS_DARK ? "white" : "black"
    );

    this.#toastType = options.toastContent
      ? options.toastContent.type
      : DEFAULT_CONFIG.toastContent.type;

    // Adding a requestAnimationFrame since we want to animate our toast. (More: https://developer.mozilla.org/en-US/docs/Web/API/window/requestAnimationFrame)
    requestAnimationFrame(() => this.#toastElement.classList.add("show"));

    // Adding a binder (passing the current element's function with `this` reference ), to close it on click, if canCloseOnClick is true.
    this.#removeBindedToast = this.removeToast.bind(this);

    this.#resume = () => (this.#isPaused = false);
    this.#pause = () => (this.#isPaused = true);
    this.#visibilityChange = () =>
      (this.#shouldResume = document.visibilityState === "visible");

    this.updateToastConfig({ ...DEFAULT_CONFIG, ...options });
  }

  //   Setters ---> START
  set position(position) {
    if (!Object.keys(ACCEPTED_TOAST_POSITIONS).includes(position))
      console.error(
        `${position} is not a valid position type. Please Refer to the documentation.`
      );

    // If we are updating the position of the toast / container on demand, then we need to make sure to remove the older container of previous position.
    const currentContainer = this.#toastElement.parentElement;

    const TOAST_CONTAINER = `.toast-container[data-position="${position}"]`;

    // Append the toast element to exisiting container or create a new one.
    const container =
      document.querySelector(TOAST_CONTAINER) || createToastContainer(position);

    // Add the toast element to DOM
    container.append(this.#toastElement);

    if (currentContainer == null || currentContainer.hasChildNodes()) return;
    currentContainer.remove();
  }

  set toastContent(toastContent) {
    const { message, title, type } = toastContent;

    if (!Object.keys(ACCEPTED_TOAST_TYPES).includes(type))
      return console.error(
        `${type} is not a valid toast type. Please Refer to the documentation.`
      );

    // this.#toastElement.textContent = message;
    this.#toastElement.innerHTML = getToastContent({
      message,
      title,
      type,
    });
  }

  set autoClose(autoClose) {
    this.#visibleSince = 0; // everytime autoClose changes, let's get a fresh visible since value to handle progress bar.
    this.#autoCloseTime = autoClose;
    if (autoClose === false || autoClose === 0) return;

    let lastTime;
    const handlePauseResume = (time) => {
      if (this.#shouldResume) {
        lastTime = null;
        this.#shouldResume = false;
      }

      if (lastTime == null) {
        lastTime = time;
        this.#autoCloseInterval = requestAnimationFrame(handlePauseResume);
        return;
      }

      //   Close the toast when not hovering
      if (!this.#isPaused) {
        this.#visibleSince += time - lastTime;
        if (this.#visibleSince >= this.#autoCloseTime) {
          this.removeToast();
          return;
        }
      }

      lastTime = time;
      this.#autoCloseInterval = requestAnimationFrame(handlePauseResume);
    };

    this.#autoCloseInterval = requestAnimationFrame(handlePauseResume);
  }

  set canCloseOnClick(value) {
    // Hide the `x` button on the toast if canCloseOnClick is false.
    this.#toastElement.classList.toggle("can-close", value);
    this.#toastElement.style.setProperty(
      "--closeIconColor",
      toastTypeColorCodeMap[this.#toastType]
    );

    if (!value) return;
    this.#toastElement.addEventListener("click", this.#removeBindedToast);
  }

  set showProgressBar(showProgressBar) {
    this.#toastElement.classList.toggle(
      "progress",
      showProgressBar && this.#autoCloseTime > 0
    );
    if (!showProgressBar) return;

    this.#toastElement.style.setProperty("--progress", 1);
    this.#toastElement.style.setProperty(
      "--progressBackground",
      toastTypeColorCodeMap[this.#toastType]
    );

    const handleProgress = () => {
      // Decrease the progress value only when not paused.
      if (!this.#isPaused) {
        this.#toastElement.style.setProperty(
          "--progress",
          1 - this.#visibleSince / this.#autoCloseTime
        );
      }
      this.#progressInterval = requestAnimationFrame(handleProgress);
    };

    this.#progressInterval = requestAnimationFrame(handleProgress);
  }

  set pauseOnHover(shouldPauseOnHover) {
    if (shouldPauseOnHover) {
      this.#toastElement.addEventListener("mouseover", this.#pause);
      this.#toastElement.addEventListener("mouseleave", this.#resume);
    } else {
      this.#toastElement.removeEventListener("mouseover", this.#pause);
      this.#toastElement.removeEventListener("mouseleave", this.#resume);
    }
  }

  set pauseOnFocusLoss(shouldPauseOnFocusLoss) {
    if (shouldPauseOnFocusLoss) {
      document.addEventListener("visibilitychange", this.#visibilityChange);
    } else {
      document.removeEventListener("visibilitychange", this.#visibilityChange);
    }
  }

  set playNotificationSound(shouldPlayNotificationSound) {
    if (!shouldPlayNotificationSound) return;

    this.#shouldPlaySound = true;

    const notificationSoundEffect = new Audio(
      `${AUDIO_ASSETS_PATH}/${Object.keys(ACCEPTED_TOAST_TYPES).find(
        (type) => type === this.#toastType
      )}.mp3`
    );

    if (
      navigator.vibrate &&
      [ACCEPTED_TOAST_TYPES.error, ACCEPTED_TOAST_TYPES.warning].includes(
        this.#toastType
      )
    ) {
      navigator.vibrate(500);
    }

    notificationSoundEffect.play();
  }
  //   Setters ---> END

  //   UTIL FUNCTIONS --> START
  removeToast() {
    // clear the animation frames.
    cancelAnimationFrame(this.#autoCloseInterval);
    cancelAnimationFrame(this.#progressInterval);

    const container = this.#toastElement.parentElement;

    // Let's remove the show class for fade animations when closing.
    this.#toastElement.classList.remove("show");
    this.#toastElement.addEventListener("transitionend", () => {
      this.#toastElement.remove();

      // If the current toast is the final toast OR if there are no toasts left, truncate the parent container.
      if (container == null || container.hasChildNodes()) return;
      container.remove();
    });

    if (this.#shouldPlaySound) {
      const closeSoundEffect = new Audio(`${AUDIO_ASSETS_PATH}/close.mp3`);
      closeSoundEffect.play();
    }

    // Call the onClose hook.
    this.onClose();
  }

  updateToastConfig(config) {
    // Loop through each entries and set the values. (NOTE: Respective setter has to be present)
    Object.entries(config).forEach(([key, value]) => {
      this[key] = value;
    });
  }
  //   UTIL FUNCTIONS --> END
}
