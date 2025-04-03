import Link from "next/link";

export default async function Home() {
  return (
    <div className="p-8 bg-gray-100 min-h-screen">
      <h1 className="text-4xl font-bold text-gray-800 text-center">Welcome to the Disaster Management Dashboard</h1>
      <p className="mt-6 text-lg text-gray-600 text-center">
        Navigate to the Disaster Reports section to view and manage disasters.
      </p>
      <div className="mt-10 flex justify-center">
        <Link
          href="/disasters"
          className="px-6 py-3 text-white bg-blue-600 rounded-lg shadow-lg hover:bg-blue-700 transition duration-300"
        >
          Go to Disaster Reports
        </Link>
      </div>
    </div>
  );
}
