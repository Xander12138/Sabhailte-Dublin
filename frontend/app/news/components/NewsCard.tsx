"use client";
import { Card, CardHeader, CardBody, Image } from "@heroui/react";

function NewsCard({ news }: { news: News }) {
  return (
    <Card className="py-4">
      <CardHeader className="pb-0 pt-2 px-4 flex-col items-start">
        <small className="text-default-500">{news.description}</small>
        <h4 className="font-bold text-large">{news.title}</h4>
      </CardHeader>
      <CardBody className="overflow-visible py-2">
        <Image
          alt="Card background"
          className="object-cover rounded-xl"
          src={`data:image/jpeg;base64,${news.cover_image}`}
          width={270}
        />
      </CardBody>
    </Card>
  );
}

export default NewsCard;
