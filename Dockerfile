# Use official Python image
FROM python:3.9

# Set the working directory
WORKDIR /app

# Copy app files
COPY app/ .

# Install dependencies
RUN pip install -r requirements.txt

# Expose Flask port
EXPOSE 5000

# Run Flask app
CMD ["python", "app.py"]
