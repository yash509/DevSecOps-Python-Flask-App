terraform {
  backend "s3" {
    bucket = "backend-react-app" # Replace with your actual S3 bucket name
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}