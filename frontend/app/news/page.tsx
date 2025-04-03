"use client";

import { useEffect, useState } from "react";

// Define the Disaster type
type Disaster = {
  title: string;
  description: string;
  time: string;
  location: string;
};

export default function News() {
  const [disasters, setDisasters] = useState<Disaster[]>([]); // Type disasters as an array of Disaster
  const [error, setError] = useState<string | null>(null);

  // Fetch disasters from the API
  useEffect(() => {
    async function fetchDisasters() {
      try {
        const response = await fetch("http://127.0.0.1:8000/api/disasters"); // Replace with your backend URL
        if (!response.ok) throw new Error("Failed to fetch disaster reports");
        const data = await response.json();
        setDisasters(data.disasters || []);
      } catch (err) {
        setError((err as Error).message);
      }
    }
    fetchDisasters();
  }, []);

  // Render the component
  return (
    <div className="p-8 bg-gray-100 min-h-screen">
      <h1 className="text-4xl font-bold text-center text-gray-800">Disaster Reports</h1>

      {error ? (
        <p className="text-red-500 text-center mt-6">{`Error: ${error}`}</p>
      ) : disasters.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-8">
          {disasters.map((disaster: Disaster, index) => (
            <div
              key={index}
              className="bg-white p-6 border border-gray-300 rounded-lg shadow-lg hover:shadow-xl transition-shadow duration-300"
            >
              <h2 className="text-2xl font-semibold text-gray-700">{disaster.title}</h2>
              <p className="mt-2 text-gray-600">{disaster.description}</p>
              <p className="mt-4 text-sm text-gray-500">
                <span className="font-medium">Location:</span> {disaster.location}
              </p>
              <p className="text-sm text-gray-500">
                <span className="font-medium">Time:</span> {disaster.time}
              </p>
            </div>
          ))}
        </div>
      ) : (
        <p className="text-center mt-8 text-gray-600">No disaster reports available at the moment.</p>
      )}
    </div>
  );
}
