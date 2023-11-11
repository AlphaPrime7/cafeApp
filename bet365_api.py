import requests

# API endpoint URL
url = "https://api.bet365.com/api/v1/some-endpoint"

# API credentials
username = "your-username"
password = "your-password"
secure_key = "your-secure-key"

# Set up authentication
auth = (username, password)
headers = {
    "ContentType": "application/json",
    "Authorization": f"Bearer {secure_key}"
}

# Make the API request
response = requests.get(url, auth=auth, headers=headers)

# Check the response status code
if response.status_code == 200:
    # Request successful, retrieve the data
    data = response.json()
    # Process the data as needed
    print(data)
else:
    # Request failed, handle the error
    print(f"Error: {response.status_code} - {response.text}")