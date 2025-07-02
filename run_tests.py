#!/usr/bin/env python3
"""
Simple test runner for the backend tests.
This script ensures the test environment is properly set up.
"""

import sys
import os
import subprocess

def main():
    """Run the backend tests"""
    # Ensure we're in the right directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    # Run pytest with coverage
    cmd = [
        sys.executable, "-m", "pytest",
        "tests/",
        "-v",
        "--tb=short"
    ]
    
    # Add coverage if pytest-cov is available
    try:
        import pytest_cov
        cmd.extend(["--cov=app", "--cov-report=term-missing"])
    except ImportError:
        print("pytest-cov not available, running without coverage")
    
    print("Running backend authentication tests...")
    print("Command:", " ".join(cmd))
    print("-" * 50)
    
    # Run the tests
    result = subprocess.run(cmd)
    return result.returncode

if __name__ == "__main__":
    sys.exit(main())
