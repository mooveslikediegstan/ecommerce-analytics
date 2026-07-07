from numpy import int64
import pandas as pd
import os

# Folder path (change for your own path)
folder = 'C:\\Users\\Administrador\\OneDrive\\Programming\\08_DataAnalystPath\\Projeto_Ecommerce_Vendas\\1_raw_data\\'

filename = 'olist_order_reviews_dataset.csv'

filepath = os.path.join(folder, filename)

dates_to_parse = ['review_creation_date', 'review_answer_timestamp']

df = pd.read_csv(
    filepath,
    encoding    = 'utf-8',
    dtype       = {
        'review_score'           : 'Int64',
        'review_comment_title'   : str,
        'review_comment_message' : str,
    },
    parse_dates = dates_to_parse
)

# Format the dates before exporting to CSV
for column in dates_to_parse:
    df[column] = df[column].dt.strftime('%Y-%m-%d %H:%M:%S')

text_columns = ['review_comment_title', 'review_comment_message']

for column in text_columns:
    df[column] = (
        df[column]
        .astype(str)
        .str.replace('\n', ' ', regex=False)  # replace linebreak with space
        .str.replace('\r', ' ', regex=False)  # remove carriage return also
        .str.strip()  # clean trailing and leading whitespace                         
    )


# Exporting
df.to_csv(
    filepath,
    index          = False,
    encoding       = 'utf-8',
    quoting        = 2,
    lineterminator = '\n'
)

print(f'{filename} normalized')

print('\nFile ready for BULK INSERT!')