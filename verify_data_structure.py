#!/usr/bin/env python3
"""
Verify the data structure and field mapping in MongoDB
"""

import requests
import json

BACKEND_URL = "https://hygitech-3d-showcase.preview.emergentagent.com/api"

def verify_data_structure():
    print("Verifying Contact Request Data Structure")
    print("=" * 50)
    
    try:
        # Get contact requests
        response = requests.get(f"{BACKEND_URL}/contact", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            
            if data and len(data) > 0:
                # Check the first contact request structure
                contact = data[0]
                
                print("Sample Contact Request Structure:")
                print(json.dumps(contact, indent=2))
                print()
                
                # Verify required fields
                required_fields = ['id', 'name', 'email', 'phone', 'subject', 'message', 'created_at', 'status']
                optional_fields = ['has_pets', 'has_vulnerable_people']
                
                print("Field Verification:")
                for field in required_fields:
                    if field in contact:
                        print(f"✅ {field}: {type(contact[field]).__name__}")
                    else:
                        print(f"❌ Missing required field: {field}")
                
                for field in optional_fields:
                    if field in contact:
                        print(f"✅ {field}: {type(contact[field]).__name__} = {contact[field]}")
                    else:
                        print(f"⚠️  Optional field not present: {field}")
                
                # Verify field mapping (hasPets -> has_pets, hasVulnerablePeople -> has_vulnerable_people)
                print("\nField Mapping Verification:")
                if 'has_pets' in contact:
                    print(f"✅ hasPets correctly mapped to has_pets: {contact['has_pets']}")
                else:
                    print("❌ has_pets field missing")
                    
                if 'has_vulnerable_people' in contact:
                    print(f"✅ hasVulnerablePeople correctly mapped to has_vulnerable_people: {contact['has_vulnerable_people']}")
                else:
                    print("❌ has_vulnerable_people field missing")
                
                # Verify email format
                if '@' in contact.get('email', ''):
                    print(f"✅ Email format valid: {contact['email']}")
                else:
                    print(f"❌ Email format invalid: {contact.get('email')}")
                
                # Verify default status
                if contact.get('status') == 'nouveau':
                    print(f"✅ Default status correct: {contact['status']}")
                else:
                    print(f"⚠️  Status: {contact.get('status')} (expected 'nouveau')")
                    
            else:
                print("No contact requests found in database")
                
        else:
            print(f"Failed to retrieve contact requests: HTTP {response.status_code}")
            
    except Exception as e:
        print(f"Error verifying data structure: {str(e)}")

if __name__ == "__main__":
    verify_data_structure()