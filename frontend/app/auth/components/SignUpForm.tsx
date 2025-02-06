"use client";

import { Button, Input, Link, Spinner } from "@nextui-org/react";
import { EyeFilledIcon } from "./EyeFilledIcon";
import { EyeSlashFilledIcon } from "./EyeSlashFilledIcon";
import { Dispatch, SetStateAction } from "react";
import { Options } from "nuqs";

function SignUpForm({
  email,
  setEmail,
  password,
  setPassword,
  submitSignup,
  isVisible,
  toggleVisibility,
  isInvalidEmail,
  isInvalidPassword,
  isLoading,
  setSelected,
}: {
  submitSignup: (event: any) => Promise<void>;
  isInvalidEmail: boolean;
  email: string;
  setEmail: Dispatch<SetStateAction<string>>;
  toggleVisibility: () => void;
  isVisible: boolean;
  password: string;
  setPassword: Dispatch<SetStateAction<string>>;
  isInvalidPassword: boolean;
  isLoading: boolean;
  setSelected: <Shallow>(
    value: string | ((old: string) => string | null) | null,
    options?: Options<Shallow> | undefined
  ) => Promise<URLSearchParams>;
}) {
  return (
    <form className="flex flex-col gap-4" onSubmit={submitSignup}>
      <Input
        isRequired
        label="Email"
        placeholder="Enter your email"
        type="email"
        name="email"
        autoComplete="email"
        isInvalid={isInvalidEmail}
        errorMessage={isInvalidEmail && "Please enter a valid email"}
        value={email}
        onValueChange={setEmail}
      />
      <Input
        isRequired
        label="Password"
        name="pass"
        autoComplete="new-password"
        placeholder="Enter your password"
        type={isVisible ? "text" : "password"}
        value={password}
        onValueChange={setPassword}
        isInvalid={isInvalidPassword}
        errorMessage={
          isInvalidPassword &&
          "Please create a password that is at least 8 characters long and includes at least one letter and one number."
        }
        endContent={
          <button className="focus:outline-none" type="button" onClick={toggleVisibility}>
            {isVisible ? (
              <EyeFilledIcon className="pointer-events-none text-2xl text-default-400 top-10" />
            ) : (
              <EyeSlashFilledIcon className="pointer-events-none text-2xl text-default-400" />
            )}
          </button>
        }
      />
      <div className="mt-3 flex justify-end gap-2">
        <Button fullWidth className="z-[1] cursor-pointer text-white p-0 rounded-full" type="submit">
          <div className=" bg-streamer-color bg-[length:200%] h-full w-full rounded-full gap-2 flex justify-center items-center font-bold text-lg">
            {isLoading && (
              <Spinner
                size="sm"
                classNames={{
                  circle1: "border-b-[white]",
                  circle2: "border-b-[white]",
                }}
              />
            )}
            <span>Sign up</span>
          </div>
        </Button>
      </div>
      <p className="text-center text-small">
        Already have an account?{" "}
        <Link size="sm" onPress={() => setSelected("login")} className=" text-[#71F9E1] cursor-pointer">
          Sign in
        </Link>
      </p>
    </form>
  );
}

export default SignUpForm;
