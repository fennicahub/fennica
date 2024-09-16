from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from bs4 import BeautifulSoup
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from concurrent.futures import ThreadPoolExecutor
import pandas as pd
import time

# nohup /bin/python3 undetermined_udk.py &
def search_and_extract_info(query, outlist = None):
    if outlist == None:
        outlist = []
    # Set up Chrome options
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--window-size=1920,1080")
    chrome_options.add_argument('--no-sandbox')

    # Create a service instance with the path to ChromeDriver
    s =  Service("/home/ubuntu/.wdm/drivers/chromedriver/linux64/126.0.6478.182/chromedriver-linux64/chromedriver")

    # Initialize the WebDriver with the specified options and service
    driver = webdriver.Chrome(service=s, options=chrome_options)

    print(f"{query=}")
    try:
        driver.get("https://finto.fi/udcs/fi/")
        
        search_input_locator = (By.ID, "search-field")
        WebDriverWait(driver, 10).until(EC.element_to_be_clickable(search_input_locator))
        search_input = driver.find_element(*search_input_locator)
        search_input.clear()
        search_input.send_keys(query)
        
        search_button_locator = (By.ID, "search-all-button")
        WebDriverWait(driver, 60).until(EC.element_to_be_clickable(search_button_locator))
        search_button = driver.find_element(*search_button_locator)
        search_button.click()
        
        # Attempt to scroll to the bottom of the page to ensure dynamic content loads
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        
        results_locator = (By.CLASS_NAME, "search-result")
        WebDriverWait(driver, 60).until(EC.presence_of_element_located(results_locator))
        
        page_source = driver.page_source
        soup = BeautifulSoup(page_source, 'html.parser')
        #print("Parsing HTML...")
        
        first_result = soup.find('div', class_='search-result')
        if first_result:
            notation_span = first_result.find('span', class_='notation')
            pref_label_a = first_result.find('a', class_='prefLabel conceptlabel')
            
            if notation_span and pref_label_a:
                numeric_id = notation_span.text.strip()
                title = pref_label_a.text.strip()
                output = {'udk': numeric_id, 'explanation': title}
                outlist.append(output)
                driver.quit()
                return output
        driver.quit()
            
    except Exception as e:
        #print(f"An error occurred: {e}")
        driver.quit()
        return None

df = pd.read_csv('/home/ubuntu/git/fennica/inst/examples/output.tables/UDK_discarded.csv', sep='\t')
print("CSV read")
queries = df['udk'].tolist()
queries = queries[7501:]

from concurrent.futures import ThreadPoolExecutor
import concurrent
def process_query_parallel(queries):
    all_info = []
    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = {executor.submit(search_and_extract_info, query): query for query in queries[:100]}
        for future in concurrent.futures.as_completed(futures):
            query = futures[future]
            try:
                info = future.result()
                if info:
                    all_info.append(info)
            except Exception as exc:
                print(f'Query "{query}" generated an exception: {exc}')
    return all_info
print("starting all_info")
all_info = []
with ThreadPoolExecutor(max_workers=50) as executor:
    futures = {executor.submit(search_and_extract_info, query): query for query in queries}
    for future in concurrent.futures.as_completed(futures):
        query = futures[future]
        try:
            info = future.result()
            if info:
                all_info.append(info)
        except Exception as exc:
            print(f'Query "{query}" generated an exception: {exc}')

import csv
print("all_info finished")
# Path to udk_monografia.csv
csv_path = '/home/ubuntu/git/fennica/inst/examples/udk_monografia.csv'

print("preparing new data")
# Prepare new data for appending
new_data = [f"{info['udk']};{info['explanation']}" for info in all_info]
print("appending to udk_monografia")
# Append new data to udk_monografia.csv
with open(csv_path, 'a', newline='', encoding='utf-8') as csvfile:
    writer = csv.writer(csvfile, delimiter=';')
    for row in new_data:
        writer.writerow([row])

print("Data has been appended to udk_monografia.csv.")