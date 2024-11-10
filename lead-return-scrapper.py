import os
from os import path
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.action_chains import ActionChains
from selenium.common.exceptions import NoSuchElementException, ElementNotInteractableException, TimeoutException
from bs4 import BeautifulSoup
import time
import datetime
import pandas as pd
import difflib  # Import difflib for string similarity matching
from mage_ai.data_preparation.shared.secrets import get_secret_value

# Set up WebDriver for remote use
selenium_server_url = "SELENIUM_HOST_URL"
options = Options()
options.add_argument('--headless')
options.add_argument('--disable-gpu')
options.add_argument('--no-sandbox')
options.add_argument('--disable-dev-shm-usage')

driver = webdriver.Remote(command_executor=selenium_server_url, options=options)

# Manual overrides dictionary
manual_overrides = {
    # Add any custom mappings here to correct mismatches
}

# Define the folder path for saving HTML pages
output_folder = '/path/to/output/folder'

date_selector_pressed = False

# Debugging function to save HTML source
def save_html_soup(stage):
    """Save HTML source as a formatted BeautifulSoup file."""
    page_source = driver.page_source
    soup = BeautifulSoup(page_source, 'html.parser')
    file_path = os.path.join(output_folder, f"{stage}_page.html")
    with open(file_path, "w", encoding="utf-8") as file:
        file.write(soup.prettify())
    print(f"HTML saved for {stage} stage at {file_path}.")

# Login function
def login():
    print("Attempting to log in...")
    driver.get("https://example-website.com/login")
    time.sleep(2)

    username_field = driver.find_element(By.XPATH, '//*[@id="username_field_xpath"]')
    password_field = driver.find_element(By.XPATH, '//*[@id="password_field_xpath"]')

    username = get_secret_value('example_username')
    password = get_secret_value('example_password')

    username_field.send_keys(username)
    password_field.send_keys(password)
    password_field.send_keys(Keys.RETURN)

    time.sleep(7)
    print("Login successful.")

# Date selection function
def select_date_in_datepicker(target_date):
    global date_selector_pressed
    target_datetime = datetime.datetime.strptime(target_date, '%Y-%m-%d')
    target_day = target_datetime.strftime('%d')  # Format as zero-padded two digits
    target_month_year = target_datetime.strftime('%B %Y')

    if not date_selector_pressed:
        date_selector_button = driver.find_element(By.XPATH, '//*[@id="date_selector_button_xpath"]')
        driver.execute_script("arguments[0].scrollIntoView({ behavior: 'smooth', block: 'center' });", date_selector_button)
        date_selector_button.click()
        date_selector_pressed = True

    from_date_input = driver.find_element(By.ID, 'datefilter-from')
    from_date_input.click()
    time.sleep(1)

    try:
        WebDriverWait(driver, 15).until(EC.visibility_of_element_located((By.CLASS_NAME, 'table-condensed')))
        print("Date picker is now visible.")
    except TimeoutException:
        print("Date picker did not appear in time.")
        return False

    while True:
        current_month_year = driver.find_element(By.CLASS_NAME, 'datepicker-switch').text
        if current_month_year == target_month_year:
            break
        elif target_datetime < datetime.datetime.strptime(current_month_year, '%B %Y'):
            driver.find_element(By.CLASS_NAME, 'prev').click()
        else:
            driver.find_element(By.CLASS_NAME, 'next').click()
        time.sleep(1)

    days = driver.find_elements(By.CLASS_NAME, 'day')
    for day in days:
        if day.text.zfill(2) == target_day and "disabled" not in day.get_attribute("class") and 'old' not in day.get_attribute("class"):
            day.click()
            print(f"Selected date: {target_date}")
            return True
    print("Date not found in the date picker.")
    return False

# Function to find the closest match for a return reason
def find_closest_reason(provided_reason, available_reasons):
    """
    Finds the closest matching return reason from a list of available options.

    Args:
        provided_reason (str): The reason to match.
        available_reasons (list of str): The available reasons to match against.

    Returns:
        str: The closest matching reason.
    """
    # Check if there's a manual override for this reason
    if provided_reason in manual_overrides:
        print(f"Using manual override for reason '{provided_reason}' -> '{manual_overrides[provided_reason]}'")
        return manual_overrides[provided_reason]

    # Use difflib for best match if no override found
    closest_matches = difflib.get_close_matches(provided_reason, available_reasons, n=1, cutoff=0.5)
    return closest_matches[0] if closest_matches else None

# Lead search function with date selection
def search_leads(lead_id, return_reason, lead_date):
    try:
        print(f"Searching for lead with id: {lead_id}")
        target_url = 'https://example-website.com/leads'
        if driver.current_url != target_url:
            driver.get(target_url)
            time.sleep(5)

        # Open and select date in date picker
        target_date = lead_date
        if not select_date_in_datepicker(target_date):
            print("Failed to select the date.")
            return False
        
        lead_id_search_input = driver.find_element(By.XPATH, '//*[@id="lead_search_input_xpath"]')
        lead_id_search_input.clear()
        lead_id_search_input.send_keys(lead_id)
        time.sleep(2)

        return_button = driver.find_element(By.XPATH,'//*[@id="return_button_xpath"]')
        return_button.click()
        time.sleep(2)

        reason_select_input = driver.find_element(By.XPATH, '//*[@id="reason_select_input_xpath"]')
        reason_select_input.click()
        time.sleep(1)
        reason_select_results_ul = driver.find_element(By.CLASS_NAME, 'select2-results__options')
        available_reasons = [li.text for li in reason_select_results_ul.find_elements(By.TAG_NAME, 'li')]
        print(available_reasons)

        closest_reason = find_closest_reason(return_reason, available_reasons)
        if closest_reason:
            for li in reason_select_results_ul.find_elements(By.TAG_NAME, 'li'):
                if li.text == closest_reason:
                    li.click()
                    print(f"Selected closest matching reason: {closest_reason}")
                    break
        else:
            print("No suitable reason found.")

        time.sleep(2)

        submit_button = driver.find_element(By.XPATH,'//*[@id="submit_button_xpath"]')
        submit_button.click()
        time.sleep(2)

        lead_id_search_input.clear()
        time.sleep(2)
        return True
    except:
        return False


# Main function
@custom
def main(data):
    data_df = data
    if data_df.empty:
        return pd.DataFrame()
    
    # Ensure Lead_Date is converted to datetime, then extract only the date part in 'YYYY-MM-DD' format
    data_df['Lead_Date'] = pd.to_datetime(data_df['Lead_Date'], errors='coerce').dt.strftime('%Y-%m-%d')

    login()
    successful_rejections = []

    for index, row in data_df.iterrows():
        lead_id = row["Lead_Id"]
        return_reason = row['ReturnReason']
        lead_date = row['Lead_Date']
        if search_leads(lead_id, return_reason, lead_date):
            successful_rejections.append(row)

    driver.quit()
    successful_rejections_df = pd.DataFrame(successful_rejections)

    # Format DataFrame
    formatted_df = successful_rejections_df[['Lead_Id', 'ReturnReason']].copy()
    formatted_df['Return_Date'] = datetime.datetime.now().strftime('%Y-%m-%d')
    formatted_df['Return_Submitted'] = 'Yes'
    formatted_df['Return_Status'] = 'Pending'

    return formatted_df
