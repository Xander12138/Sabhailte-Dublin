import serverGetNewList from "../utils/serverGetNewList";
import NewsCard from "./components/NewsCard";

export default async function News() {
  const newsList: News[] = await serverGetNewList();

  // Render the component
  return (
    <div className="p-8 bg-gray-100 min-h-screen">
      <h1 className="text-4xl font-bold text-center text-gray-800">Disaster Reports</h1>

      {newsList.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-8">
          {newsList.map((news: News, index) => (
            <NewsCard key={index} news={news} />
          ))}
        </div>
      ) : (
        <p className="text-center mt-8 text-gray-600">No disaster reports available at the moment.</p>
      )}
    </div>
  );
}
