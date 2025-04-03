import api from "./api";

export default async function serverGetNewList(): Promise<News[]> {
  const data = await api.getNews();
  const newsList = data.news;

  const filteredNewsList = newsList.filter((item: any) => Array.isArray(item) && item.length >= 9);

  const parsedNewsList: News[] = filteredNewsList.map((item: any) => {
    // Parse the JSON string for location
    const locationJson = JSON.parse(item[6]);
    const location: ILocation = {
      latitude: Number(locationJson.latitude),
      longitude: Number(locationJson.longitude),
    };

    const news: News = {
      news_id: String(item[0]),
      author_id: String(item[1]),
      cover_image: String(item[2]),
      title: String(item[3]),
      description: String(item[4]),
      time: String(item[5]),
      location: location,
      views: Number(item[7]),
      reaction: String(item[8]),
    };

    return news;
  });

  return parsedNewsList;
}
