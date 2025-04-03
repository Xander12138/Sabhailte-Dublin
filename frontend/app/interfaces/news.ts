// Define the Disaster type
interface News {
  news_id: string;
  author_id: string;
  cover_image: string;
  title: string;
  description: string;
  time: string;
  location: ILocation;
  views: number;
  reaction: string;
}

interface ILocation {
  latitude: Number;
  longitude: Number;
}
