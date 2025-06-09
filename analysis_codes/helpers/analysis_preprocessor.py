
def preprocess(df):
    print('Preprocessing')
    number_of_rows_earlier = len(df)
    df.dropna(how='any', inplace=True)
    rows_dropped = number_of_rows_earlier - len(df)
    print(f'Number of rows dropped: {rows_dropped}')
    df['id'] = df['id'].astype(int)
    df['like_count'] = df['like_count'].astype(int)
    df['retweet_count'] = df['retweet_count'].astype(int)
    print('Fixed the dtypes')
    df.set_index("id", inplace=True)
    print('Set the index to id')
    df.rename(columns={'date': 'created_at', 'content': 'text'}, inplace=True)
    print('Renamed the columns')
    df.drop_duplicates(inplace=True)
    print('Dropped the duplicates')
    df['engagement_count'] = df['like_count'] + df['retweet_count']
    print('Created the engagement count column')
    df['hashtags'] = df['text'].apply(lambda text: [word for word in text.split(' ') if word.startswith('#') and len(word) > 1])
    print('Extracted hashtags')
    return df


