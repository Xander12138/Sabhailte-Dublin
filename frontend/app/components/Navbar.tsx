"use client";

import React from "react";
import { Navbar, NavbarBrand, NavbarContent, NavbarItem, Link, Button } from "@heroui/react";
import { auth } from "@/lib/firebase/auth";
import { signOut } from "firebase/auth";
import { usePathname } from "next/navigation";

function CustomNavbar() {
  const pathname = usePathname();

  // Handle sign-out
  const handleSignOut = async () => {
    try {
      await signOut(auth); // Sign out from Firebase
      // Clear the token cookie
      document.cookie = "token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT; Secure; SameSite=Strict";
      // Redirect to homepage (or another page)
      window.location.reload();
    } catch (error) {
      console.error("Sign Out Error:", error);
    }
  };
  return (
    <Navbar>
      <NavbarBrand>
        <Link href="/" className="font-bold text-inherit text-2xl text-red-500">
          <img src="/logo.png" alt="Logo" className="h-8 w-8 mr-2" />
          Sabhailte Dublin
        </Link>
      </NavbarBrand>
      <NavbarContent className="hidden sm:flex gap-4" justify="center">
        <NavbarItem>
          <Link
            color={pathname === "/news" ? "primary" : "foreground"} // Blue if active, default otherwise
            href="/news"
          >
            News
          </Link>
        </NavbarItem>
        <NavbarItem>
          <Link
            color={pathname === "/customers" ? "primary" : "foreground"} // Blue if active
            href="/customers" // Updated href to a valid route
          >
            Customers
          </Link>
        </NavbarItem>
        <NavbarItem>
          <Link
            color={pathname === "/integrations" ? "primary" : "foreground"} // Blue if active
            href="/integrations" // Updated href to a valid route
          >
            Integrations
          </Link>
        </NavbarItem>
      </NavbarContent>
      <NavbarContent justify="end">
        <NavbarItem>
          <Button
            color="danger"
            variant="flat"
            onPress={handleSignOut} // Call sign-out function on click
          >
            Sign Out
          </Button>
        </NavbarItem>
      </NavbarContent>
    </Navbar>
  );
}

export default CustomNavbar;
