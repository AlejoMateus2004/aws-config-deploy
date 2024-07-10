import boto3
import csv
import logging
from datetime import datetime
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    current_time = datetime.now()
    logger.info(f"Lambda function executed at {current_time}")
    dynamodb = boto3.resource('dynamodb')
    s3 = boto3.client('s3')

    table_name = os.environ['DYNAMODB_TABLE']
    S3_BUCKET_NAME = os.environ['S3_BUCKET']

    table = dynamodb.Table(table_name)

    try:
        current_date = datetime.now().strftime('%Y_%B')
        year = current_date[:4]
        month = current_date[5:]
        
        report_data = []
    
        response = table.scan(
            ProjectionExpression='TrainerFirstName, TrainerLastName, YearList'
        )
        items = response['Items']
    
        for item in items:
            trainer_first_name = item['TrainerFirstName']
            trainer_last_name = item['TrainerLastName']
            training_summary = 0
            
            
            years_data = item['YearList']
            if year in years_data:  # Año actual
                year_data = years_data[year]
                if month in year_data:  # Mes actual
                    training_summary = int(year_data[month])
    
            if training_summary > 0:
                report_data.append([trainer_first_name, trainer_last_name, training_summary])
    
        if report_data and len(report_data) > 0:
     
            report_name = f"Trainers_Trainings_summary_{year}_{month}.csv"
            
            with open(f"/tmp/{report_name}", mode='w', newline='') as file:
                writer = csv.writer(file)
                writer.writerow(['Trainer First Name', 'Trainer Last Name', 'Training Duration'])
                for row in report_data:
                    writer.writerow(row)
            
            s3.upload_file(f"/tmp/{report_name}", S3_BUCKET_NAME, f"lambda_reports/{report_name}")
            
            return {
            'statusCode': 200,
            'body': f"Report {report_name} generated and uploaded to S3 bucket {S3_BUCKET_NAME}."
        }
        else:
            print("Array is empty.")

        return {
            'statusCode': 200,
            'body': f"Report not generated, array is empty."
        }

        
        
    except Exception as e:
        print(f"Error processing function: {e}")
        return {
            "statusCode": 500,
            "body": f"Error processing function: {e}"
        }
    