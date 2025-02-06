// SignInorUpCard.js
"use client";

import { GoogleAuthProvider, signInWithPopup } from "firebase/auth";
import { auth } from "@/lib/firebase/auth"; // Adjust the import path as necessary
import { Button } from "@nextui-org/react";

const SignInorUpCard = () => {
  const handleGoogleSignIn = async () => {
    const provider = new GoogleAuthProvider();
    const result = await signInWithPopup(auth, provider);
    // This gives you a Google Access Token. You can use it to access the Google API.
    const credential = GoogleAuthProvider.credentialFromResult(result);
    const token = credential?.accessToken;
    // The signed-in user info.
    const user = result.user;
    console.log("User Info:", user);
  };

  return (
    <div className="w-full h-full flex items-center justify-center">
      <Button onClick={handleGoogleSignIn}>Sign in with Google</Button>
    </div>
  );
};

export default SignInorUpCard;
