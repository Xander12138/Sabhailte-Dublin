"use client";
import { Modal, ModalContent, ModalHeader, ModalBody, Button, Input, Spinner } from "@heroui/react";
import { useState } from "react";
import { EyeFilledIcon } from "./EyeFilledIcon";
import { EyeSlashFilledIcon } from "./EyeSlashFilledIcon";
import { GoogleAuthProvider, signInWithPopup, signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "@/lib/firebase/auth"; // Adjust the import path as necessary
import { FaGoogle } from "react-icons/fa6";

function AuthModal({ open }: { open: boolean }) {
  const [isOpen, setIsOpen] = useState(open);
  const [isLoading, setIsLoading] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isVisible, setIsVisible] = useState(false);
  const [error, setError] = useState<string | null>(null); // Add error state for feedback

  const toggleVisibility = () => setIsVisible((prev) => !prev);

  // Google Sign-In
  const handleGoogleSignIn = async () => {
    setIsLoading(true);
    setError(null); // Clear any previous errors
    try {
      const provider = new GoogleAuthProvider();
      const result = await signInWithPopup(auth, provider);
      const user = result.user;
      const idToken = await user.getIdToken();

      // Set token in cookie
      document.cookie = `token=${idToken}; path=/; Secure; SameSite=Strict`;
      setIsOpen(false);
    } catch (error: any) {
      console.error("Google Sign-In Error:", error);
      setError(error.message || "Failed to sign in with Google");
    } finally {
      setIsLoading(false);
    }
  };

  // Email/Password Sign-In
  const handleEmailSignIn = async (e: React.FormEvent) => {
    e.preventDefault(); // Prevent form submission from refreshing the page
    setIsLoading(true);
    setError(null); // Clear any previous errors

    try {
      const result = await signInWithEmailAndPassword(auth, email, password);
      const user = result.user;
      const idToken = await user.getIdToken();

      // Set token in cookie
      document.cookie = `token=${idToken}; path=/; Secure; SameSite=Strict`;
      setIsOpen(false);
    } catch (error: any) {
      console.error("Email/Password Sign-In Error:", error);
      setError(error.message || "Invalid email or password");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      {isOpen && (
        <Modal isOpen={isOpen} onClose={() => setIsOpen(false)} hideCloseButton shouldBlockScroll isDismissable={false}>
          <ModalContent>
            <>
              <ModalHeader className="flex flex-col gap-1">Sign In</ModalHeader>
              <ModalBody className="p-5">
                <form className="flex flex-col gap-4" onSubmit={handleEmailSignIn}>
                  <Input
                    isRequired
                    label="Email"
                    placeholder="Enter your email"
                    type="email"
                    autoComplete="email"
                    value={email}
                    onValueChange={setEmail}
                  />
                  <Input
                    isRequired
                    label="Password"
                    placeholder="Enter your password"
                    type={isVisible ? "text" : "password"}
                    name="pass"
                    autoComplete="current-password"
                    value={password}
                    onValueChange={setPassword}
                    endContent={
                      <button className="focus:outline-none" type="button" onClick={toggleVisibility}>
                        {isVisible ? (
                          <EyeFilledIcon className="pointer-events-none text-2xl text-default-400" />
                        ) : (
                          <EyeSlashFilledIcon className="pointer-events-none text-2xl text-default-400" />
                        )}
                      </button>
                    }
                  />
                  {error && <p className="text-red-500 text-sm">{error}</p>} {/* Display error message */}
                  <div className="mt-3 flex flex-col items-center justify-center gap-5">
                    <Button
                      fullWidth
                      className="rounded-full bg-blue-500 text-white text-lg"
                      type="submit"
                      isDisabled={isLoading}
                    >
                      {isLoading && (
                        <Spinner
                          size="sm"
                          classNames={{
                            circle1: "border-b-[white]",
                            circle2: "border-b-[white]",
                          }}
                        />
                      )}
                      Sign in
                    </Button>
                    <Button
                      onPress={handleGoogleSignIn}
                      startContent={<FaGoogle className="text-gray-800" />}
                      fullWidth
                      className="rounded-full border-2 border-gray-300 bg-white text-gray-600"
                      variant="bordered"
                      isDisabled={isLoading}
                    >
                      Continue with Google
                    </Button>
                  </div>
                </form>
              </ModalBody>
            </>
          </ModalContent>
        </Modal>
      )}
    </>
  );
}

export default AuthModal;
