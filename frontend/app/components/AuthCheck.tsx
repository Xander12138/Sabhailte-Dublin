import React from "react";
import admin from "firebase-admin";
import AuthModal from "./AuthModal";
import { cookies } from "next/headers";

async function AuthCheck() {
  const cookieStore = await cookies();
  const token = cookieStore.get("token")?.value;
  let showAuthModal = true;

  try {
    if (token) {
      await admin.auth().verifyIdToken(token);
      showAuthModal = false; // Token is valid, don’t show modal
    }
  } catch (error) {
    console.error("Token verification error:", error);
    showAuthModal = true; // Invalid token, show modal
  }
  return <AuthModal open={showAuthModal} />;
}

export default AuthCheck;
