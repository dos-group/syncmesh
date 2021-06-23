#arg1 -> csv file name 
#arg2 -> column name of attribute we want to get avg from

import pandas as pd
import sys

csv_file = sys.argv[1]
attribute = sys.argv[2]

data = pd.read_csv(csv_file)

print(data[attribute].mean())
