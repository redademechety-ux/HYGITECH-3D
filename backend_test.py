#!/usr/bin/env python3
"""
Backend Test Suite for HYGITECH-3D Contact Form API
Tests the contact form endpoints according to test_result.md requirements
"""

import requests
import json
import sys
from datetime import datetime
import uuid

# Configuration
BACKEND_URL = "https://hygitech-3d-showcase.preview.emergentagent.com/api"

class BackendTester:
    def __init__(self):
        self.test_results = []
        self.failed_tests = []
        
    def log_test(self, test_name, success, message, details=None):
        """Log test results"""
        result = {
            'test': test_name,
            'success': success,
            'message': message,
            'details': details,
            'timestamp': datetime.now().isoformat()
        }
        self.test_results.append(result)
        
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status}: {test_name}")
        print(f"   {message}")
        if details:
            print(f"   Details: {details}")
        print()
        
        if not success:
            self.failed_tests.append(result)
    
    def test_contact_form_valid_submission(self):
        """Test valid contact form submission"""
        test_data = {
            "name": "Marie Dubois",
            "email": "marie.dubois@email.com",
            "phone": "06 12 34 56 78",
            "subject": "Demande de devis désinfection",
            "message": "Bonjour, je souhaiterais obtenir un devis pour la désinfection de mon appartement de 80m². J'ai des animaux domestiques.",
            "hasPets": True,
            "hasVulnerablePeople": False
        }
        
        try:
            response = requests.post(f"{BACKEND_URL}/contact", json=test_data, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and data.get('id') and data.get('message'):
                    self.log_test(
                        "Valid Contact Form Submission",
                        True,
                        f"Contact form submitted successfully with ID: {data.get('id')}"
                    )
                    return data.get('id')
                else:
                    self.log_test(
                        "Valid Contact Form Submission",
                        False,
                        "Response missing required fields",
                        f"Response: {data}"
                    )
            else:
                self.log_test(
                    "Valid Contact Form Submission",
                    False,
                    f"HTTP {response.status_code}: {response.text}"
                )
        except Exception as e:
            self.log_test(
                "Valid Contact Form Submission",
                False,
                f"Request failed: {str(e)}"
            )
        return None
    
    def test_contact_form_invalid_email(self):
        """Test contact form with invalid email"""
        test_data = {
            "name": "Jean Martin",
            "email": "invalid-email",
            "phone": "06 98 76 54 32",
            "subject": "Test email invalide",
            "message": "Test avec email invalide",
            "hasPets": False,
            "hasVulnerablePeople": True
        }
        
        try:
            response = requests.post(f"{BACKEND_URL}/contact", json=test_data, timeout=10)
            
            if response.status_code == 422:  # Validation error expected
                self.log_test(
                    "Invalid Email Validation",
                    True,
                    "Invalid email correctly rejected with 422 status"
                )
            else:
                self.log_test(
                    "Invalid Email Validation",
                    False,
                    f"Expected 422 but got {response.status_code}: {response.text}"
                )
        except Exception as e:
            self.log_test(
                "Invalid Email Validation",
                False,
                f"Request failed: {str(e)}"
            )
    
    def test_contact_form_missing_fields(self):
        """Test contact form with missing required fields"""
        test_data = {
            "name": "Pierre Durand",
            "email": "pierre.durand@email.com",
            # Missing phone, subject, message
            "hasPets": False,
            "hasVulnerablePeople": False
        }
        
        try:
            response = requests.post(f"{BACKEND_URL}/contact", json=test_data, timeout=10)
            
            if response.status_code == 422:  # Validation error expected
                self.log_test(
                    "Missing Required Fields Validation",
                    True,
                    "Missing fields correctly rejected with 422 status"
                )
            else:
                self.log_test(
                    "Missing Required Fields Validation",
                    False,
                    f"Expected 422 but got {response.status_code}: {response.text}"
                )
        except Exception as e:
            self.log_test(
                "Missing Required Fields Validation",
                False,
                f"Request failed: {str(e)}"
            )
    
    def test_contact_form_optional_fields(self):
        """Test contact form with only required fields (optional fields default)"""
        test_data = {
            "name": "Sophie Laurent",
            "email": "sophie.laurent@email.com",
            "phone": "07 11 22 33 44",
            "subject": "Demande d'information",
            "message": "Je souhaite des informations sur vos services de désinfection pour bureau."
            # hasPets and hasVulnerablePeople should default to False
        }
        
        try:
            response = requests.post(f"{BACKEND_URL}/contact", json=test_data, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and data.get('id'):
                    self.log_test(
                        "Optional Fields Default Values",
                        True,
                        f"Form submitted successfully with defaults, ID: {data.get('id')}"
                    )
                    return data.get('id')
                else:
                    self.log_test(
                        "Optional Fields Default Values",
                        False,
                        "Response missing required fields",
                        f"Response: {data}"
                    )
            else:
                self.log_test(
                    "Optional Fields Default Values",
                    False,
                    f"HTTP {response.status_code}: {response.text}"
                )
        except Exception as e:
            self.log_test(
                "Optional Fields Default Values",
                False,
                f"Request failed: {str(e)}"
            )
        return None
    
    def test_get_contact_requests(self):
        """Test GET /api/contact endpoint (admin functionality)"""
        try:
            response = requests.get(f"{BACKEND_URL}/contact", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    self.log_test(
                        "Get Contact Requests",
                        True,
                        f"Successfully retrieved {len(data)} contact requests"
                    )
                    
                    # Check if data is sorted by date (most recent first)
                    if len(data) > 1:
                        dates = [item.get('created_at') for item in data if item.get('created_at')]
                        if len(dates) > 1:
                            # Check if sorted in descending order
                            is_sorted = all(dates[i] >= dates[i+1] for i in range(len(dates)-1))
                            if is_sorted:
                                self.log_test(
                                    "Contact Requests Date Sorting",
                                    True,
                                    "Contact requests correctly sorted by date (descending)"
                                )
                            else:
                                self.log_test(
                                    "Contact Requests Date Sorting",
                                    False,
                                    "Contact requests not properly sorted by date"
                                )
                else:
                    self.log_test(
                        "Get Contact Requests",
                        False,
                        "Response is not a list",
                        f"Response type: {type(data)}"
                    )
            else:
                self.log_test(
                    "Get Contact Requests",
                    False,
                    f"HTTP {response.status_code}: {response.text}"
                )
        except Exception as e:
            self.log_test(
                "Get Contact Requests",
                False,
                f"Request failed: {str(e)}"
            )
    
    def test_get_contact_requests_with_filter(self):
        """Test GET /api/contact with status filter"""
        try:
            response = requests.get(f"{BACKEND_URL}/contact?status=nouveau", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    # Check if all returned items have status "nouveau"
                    all_nouveau = all(item.get('status') == 'nouveau' for item in data)
                    if all_nouveau:
                        self.log_test(
                            "Contact Requests Status Filter",
                            True,
                            f"Successfully filtered {len(data)} requests with status 'nouveau'"
                        )
                    else:
                        self.log_test(
                            "Contact Requests Status Filter",
                            False,
                            "Some returned requests don't have status 'nouveau'"
                        )
                else:
                    self.log_test(
                        "Contact Requests Status Filter",
                        False,
                        "Response is not a list"
                    )
            else:
                self.log_test(
                    "Contact Requests Status Filter",
                    False,
                    f"HTTP {response.status_code}: {response.text}"
                )
        except Exception as e:
            self.log_test(
                "Contact Requests Status Filter",
                False,
                f"Request failed: {str(e)}"
            )
    
    def test_backend_connectivity(self):
        """Test basic backend connectivity"""
        try:
            response = requests.get(f"{BACKEND_URL}/", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('message') == 'Hello World':
                    self.log_test(
                        "Backend Connectivity",
                        True,
                        "Backend is accessible and responding correctly"
                    )
                else:
                    self.log_test(
                        "Backend Connectivity",
                        False,
                        "Backend responding but with unexpected message",
                        f"Response: {data}"
                    )
            else:
                self.log_test(
                    "Backend Connectivity",
                    False,
                    f"HTTP {response.status_code}: {response.text}"
                )
        except Exception as e:
            self.log_test(
                "Backend Connectivity",
                False,
                f"Cannot connect to backend: {str(e)}"
            )
    
    def run_all_tests(self):
        """Run all backend tests"""
        print("=" * 60)
        print("HYGITECH-3D Backend API Test Suite")
        print("=" * 60)
        print(f"Testing backend at: {BACKEND_URL}")
        print()
        
        # Test basic connectivity first
        self.test_backend_connectivity()
        
        # Test contact form endpoints
        self.test_contact_form_valid_submission()
        self.test_contact_form_invalid_email()
        self.test_contact_form_missing_fields()
        self.test_contact_form_optional_fields()
        
        # Test admin endpoints
        self.test_get_contact_requests()
        self.test_get_contact_requests_with_filter()
        
        # Print summary
        print("=" * 60)
        print("TEST SUMMARY")
        print("=" * 60)
        
        total_tests = len(self.test_results)
        passed_tests = total_tests - len(self.failed_tests)
        
        print(f"Total Tests: {total_tests}")
        print(f"Passed: {passed_tests}")
        print(f"Failed: {len(self.failed_tests)}")
        print(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
        
        if self.failed_tests:
            print("\nFAILED TESTS:")
            for test in self.failed_tests:
                print(f"- {test['test']}: {test['message']}")
        
        print("\n" + "=" * 60)
        
        return len(self.failed_tests) == 0

if __name__ == "__main__":
    tester = BackendTester()
    success = tester.run_all_tests()
    sys.exit(0 if success else 1)