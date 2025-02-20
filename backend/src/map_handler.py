import os

import flexpolyline as fp
import requests


def fetch_route_from_api():
    """Fetches the route from the HERE API."""
    API_KEY = os.getenv('API_KEY'),

    # Parameters for API request
    origin = '53.3441,-6.2573'
    destination = '53.3430,-6.2672'
    avoid_areas = 'bbox:-6.2700,53.3420,-6.2500,53.3460'
    url = 'https://router.hereapi.com/v8/routes'
    params = {
        'origin': origin,
        'destination': destination,
        'transportMode': 'car',
        'avoid[areas]': avoid_areas,
        'return': 'polyline',
        'apiKey': API_KEY
    }

    # Send Get Request
    response = requests.get(url, params=params)
    response.raise_for_status()

    data = response.json()
    route_map = data['routes'][0]['sections'][0]['polyline']
    print('-->', route_map)
    decode_route_map = fp.decode(route_map)

    return decode_route_map


def get_evacuate_map():
    """Generates the evacuation map with route and restricted areas.

    :return: A dictionary containing 'route_map' and 'restrict_areas'.
    """

    # Mock restricted areas
    mock_restrict_areas = [
        (53.3460, -6.2700),  # Top left corner
        (53.3460, -6.2500),  # Top right corner
        (53.3420, -6.2500),  # Bottom right corner
        (53.3420, -6.2700),  # Bottom left corner
        (53.3460, -6.2700),  # Back to starting point
    ]

    return {'route_map': fetch_route_from_api(), 'restrict_areas': mock_restrict_areas}
