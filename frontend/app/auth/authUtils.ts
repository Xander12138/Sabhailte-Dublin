import axios from "axios";

const info =
  process.env.NODE_ENV === "production"
    ? {
        redirect: process.env.NEXT_PUBLIC_REDIRECT_PROD,
        apiDomain: process.env.NEXT_PUBLIC_USERBILLING_SERVICE,
        apiBasePath: "/auth",
      }
    : {
        redirect: "http://localhost:3000",
        apiDomain: process.env.NEXT_PUBLIC_USERBILLING_SERVICE,
        apiBasePath: "/auth",
      };

const generateEmailPasswordFormFields = (email: string, password: string): { id: string; value: string }[] => {
  const formFields: { id: string; value: string }[] = [
    {
      id: "email",
      value: email,
    },
    {
      id: "password",
      value: password,
    },
  ];

  return formFields;
};

async function signUpClicked(email: string, password: string) {
  try {
    const response = await emailPasswordSignUp({
      formFields: generateEmailPasswordFormFields(email, password),
    });

    if (response.status === "FIELD_ERROR") {
      response.formFields.forEach((formField) => {
        if (formField.id === "email") {
          error(formField.error);
        } else if (formField.id === "password") {
          error(formField.error);
        }
      });
    } else if (response.status === "SIGN_UP_NOT_ALLOWED") {
      error("Sign up is currently disabled.");
    } else {
      const user = response.user;
      await setUserInfo({ userId: user.id, userEmail: email });
      message("Sign Up Success.");
      // window.location.href = "/";
      return true;
    }
  } catch (err: any) {
    if (err.isSuperTokensGeneralError === true) {
      // this may be a custom error message sent from the API by you.
      window.alert(err.message);
    } else {
      window.alert("Oops! Something went wrong.");
    }
  }
}

/**
 * Sign in with email and password
 *
 * @param email user email
 * @param password user password
 * @returns
 */
async function signInClicked(email: string, password: string) {
  try {
    const response = await emailPasswordSignIn({
      formFields: generateEmailPasswordFormFields(email, password),
    });

    switch (response.status) {
      case "FIELD_ERROR":
        response.formFields.forEach((formField) => {
          if (formField.id === "email") {
            error(formField.error);
          } else if (formField.id === "password") {
            error(formField.error);
          }
        });
        break;
      case "WRONG_CREDENTIALS_ERROR":
        error("Email password combination is incorrect.");
        break;
      case "SIGN_IN_NOT_ALLOWED":
        // this can happen due to automatic account linking. Tell the user that their
        // input credentials is wrong (so that they do through the password reset flow)
        break;
      default:
        const user = response.user;
        await setUserInfo({ userId: user.id });
        // window.location.href = "/";
        return true;
        break;
    }
  } catch (err: any) {
    if (err.isSuperTokensGeneralError === true) {
      // this may be a custom error message sent from the API by you.
      error(err.message);
    } else {
      error("Oops! Something went wrong.");
    }
  }
}

async function sendEmailClicked(email: string) {
  try {
    let response = await sendPasswordResetEmail({
      formFields: [
        {
          id: "email",
          value: email,
        },
      ],
    });

    if (response.status === "FIELD_ERROR") {
      // one of the input formFields failed validaiton
      response.formFields.forEach((formField) => {
        if (formField.id === "email") {
          // Email validation failed (for example incorrect email syntax).
          error(formField.error);
        }
      });
    } else if (response.status === "PASSWORD_RESET_NOT_ALLOWED") {
      // this can happen due to automatic account linking. Please read our account linking docs
    } else {
      // reset password email sent.
      // success("Please check your email for the password reset link")
      return true;
    }
  } catch (err: any) {
    console.log(err);
    if (err.isSuperTokensGeneralError === true) {
      // this may be a custom error message sent from the API by you.
      error(err.message);
    } else {
      error("Oops! Something went wrong.");
    }
  }
}

async function newPasswordEntered(newPassword: string) {
  try {
    let response = await submitNewPassword({
      formFields: [
        {
          id: "password",
          value: newPassword,
        },
      ],
    });

    if (response.status === "FIELD_ERROR") {
      response.formFields.forEach((formField) => {
        if (formField.id === "password") {
          // New password did not meet password criteria on the backend.
          error(formField.error);
        }
      });
    } else if (response.status === "RESET_PASSWORD_INVALID_TOKEN_ERROR") {
      // the password reset token in the URL is invalid, expired, or already consumed
      error("Password reset failed. Please try again");
      window.location.assign("/auth?prev_url=/"); // back to the login scree.
    } else {
      success("Password reset successful!");
      window.location.assign("/auth?prev_url=/");
    }
  } catch (err: any) {
    if (err.isSuperTokensGeneralError === true) {
      // this may be a custom error message sent from the API by you.
      error(err.message);
    } else {
      error("Oops! Something went wrong.");
    }
  }
}

async function logoutClicked() {
  Cookies.remove("userInfo");
  sessionStorage.removeItem("newChatUser");
  logEvent("sign_out");
  await Session.signOut();
  window.location.href = "/";
}

async function setUserInfo(userInfo: UserInfo) {
  if (userInfo.userId && userInfo.userEmail) {
    Cookies.set("userInfo", JSON.stringify(userInfo), { expires: 90 });
    return userInfo;
  }
  const userId = userInfo.userId;

  // for email password code path, info
  const response = await axios.get(`${info.apiDomain}/users/${userId}`, {
    headers: {
      Authorization: "Basic ZGV2OmRlY29kYQ==",
    },
  });

  if (response.data) {
    userInfo.userEmail = response.data.email;
  }

  Cookies.set("userInfo", JSON.stringify(userInfo), { expires: 90 });
  return userInfo;
}

export { setUserInfo, logoutClicked, newPasswordEntered, sendEmailClicked, signInClicked, signUpClicked };
