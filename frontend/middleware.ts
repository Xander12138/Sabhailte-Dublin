import { NextResponse, type NextRequest } from "next/server";

export async function middleware(request: NextRequest) {
  const token = request.cookies.get("token")?.value;

  // If no token is present, set the header to show the modal
  if (!token) {
    const response = NextResponse.next();
    response.headers.set("x-show-auth-modal", "true");
    return response;
  }

  // If token exists, proceed without verification here (verification moved to page)
  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
};
