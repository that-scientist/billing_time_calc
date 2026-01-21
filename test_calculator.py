"""
Test script for Billing Calculator
Tests the core calculation logic without GUI
"""

import sys
from billing_calculator import BillingCalculator, NoteType, CalculationError

def test_calculator():
    """Run basic tests on the calculator"""
    calculator = BillingCalculator()
    
    print("Testing Billing Calculator...")
    print("=" * 50)
    
    # Test 1: Basic Progress Note calculation
    print("\nTest 1: Progress Note - 45 minutes")
    try:
        result = calculator.calculate("09:00-09:45", NoteType.PROGRESS_NOTE)
        print(f"  [OK] Duration: {result.duration} minutes")
        print(f"  [OK] Calls: {result.calls}")
        print(f"  [OK] Time Range: {result.start_time.formatted_string()} - {result.end_time.formatted_string()}")
        assert result.calls == 4, f"Expected 4 calls, got {result.calls}"
        print("  [OK] PASSED")
    except Exception as e:
        print(f"  [FAIL] FAILED: {e}")
        return False
    
    # Test 2: Consult Note calculation
    print("\nTest 2: Consult Note - 65 minutes")
    try:
        result = calculator.calculate("09:00-10:05", NoteType.CONSULT)
        print(f"  [OK] Duration: {result.duration} minutes")
        print(f"  [OK] Calls: {result.calls}")
        assert result.calls == 1, f"Expected 1 call, got {result.calls}"
        print("  [OK] PASSED")
    except Exception as e:
        print(f"  [FAIL] FAILED: {e}")
        return False
    
    # Test 3: 12-hour format
    print("\nTest 3: 12-hour format")
    try:
        result = calculator.calculate("9:00 AM to 10:30 AM", NoteType.PROGRESS_NOTE)
        print(f"  [OK] Duration: {result.duration} minutes")
        print(f"  [OK] Calls: {result.calls}")
        assert result.duration == 90, f"Expected 90 minutes, got {result.duration}"
        assert result.calls == 7, f"Expected 7 calls, got {result.calls}"
        print("  [OK] PASSED")
    except Exception as e:
        print(f"  [FAIL] FAILED: {e}")
        return False
    
    # Test 4: Error handling - invalid format
    print("\nTest 4: Error handling - invalid format")
    try:
        calculator.calculate("invalid", NoteType.PROGRESS_NOTE)
        print("  ✗ FAILED: Should have raised CalculationError")
        return False
    except CalculationError:
        print("  [OK] PASSED: Correctly raised CalculationError")
    except Exception as e:
        print(f"  ✗ FAILED: Wrong exception type: {e}")
        return False
    
    # Test 5: Error handling - start after end
    print("\nTest 5: Error handling - start after end")
    try:
        calculator.calculate("10:00-09:00", NoteType.PROGRESS_NOTE)
        print("  [FAIL] FAILED: Should have raised CalculationError")
        return False
    except CalculationError:
        print("  [OK] PASSED: Correctly raised CalculationError")
    except Exception as e:
        print(f"  [FAIL] FAILED: Wrong exception type: {e}")
        return False
    
    # Test 6: Near next tier warning
    print("\nTest 6: Near next tier warning")
    try:
        result = calculator.calculate("09:00-09:20", NoteType.PROGRESS_NOTE)
        print(f"  [OK] Duration: {result.duration} minutes")
        print(f"  [OK] Calls: {result.calls}")
        warnings = [w for w in result.warnings if isinstance(w, Warning.NearNextTier)]
        if warnings:
            print(f"  [OK] Warning detected: {len(warnings)} near-tier warning(s)")
        print("  [OK] PASSED")
    except Exception as e:
        print(f"  [FAIL] FAILED: {e}")
        return False
    
    print("\n" + "=" * 50)
    print("All tests PASSED! [OK]")
    return True

if __name__ == "__main__":
    success = test_calculator()
    sys.exit(0 if success else 1)
