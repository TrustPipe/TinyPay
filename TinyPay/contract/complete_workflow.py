#!/usr/bin/env python3
"""
Complete workflow script for TinyPay payment process.
This script demonstrates the full process from initial data to contract parameters.
Supports both Aptos (Move) and Solana platforms.
"""
import hashlib
import json
from hex_to_ascii_bytes import hex_to_ascii_bytes

def compute_hash_hex_solana(data: bytes) -> bytes:
    """
    Solana-style hash computation:
    1. Compute SHA256 hash of data
    2. Convert hash to hex string
    3. Return hex string as UTF-8 bytes
    
    This matches the TypeScript implementation:
    const hash = crypto.createHash("sha256").update(data).digest();
    return Buffer.from(hash.toString("hex"), "utf-8");
    """
    hash_digest = hashlib.sha256(data).digest()
    hash_hex = hash_digest.hex()
    return hash_hex.encode('utf-8')

def complete_payment_workflow_aptos(initial_data: str, iterations: int = 1000):
    """
    Aptos workflow: Uses ASCII-encoded hex strings for hashing.
    
    Args:
        initial_data: Initial string data
        iterations: Number of SHA256 iterations
    
    Returns:
        dict: Contains all necessary data for Aptos Move contract call
    """
    print(f"=== TinyPay Payment Workflow (Aptos) ===")
    print(f"Initial data: {initial_data}")
    print(f"Iterations: {iterations}")
    print()
    
    # Step 1: Perform iterative hashing (Aptos style)
    s = initial_data.encode()
    iteration_results = []
    
    for i in range(iterations):
        h = hashlib.sha256(s).hexdigest()
        iteration_results.append(h)
        if i < 3 or i >= iterations - 3:
            print(f"Iteration {i+1}: {h}")
        elif i == 3:
            print("...")
        s = h.encode("ascii")  # Aptos: hash the hex string as ASCII
    
    print()
    
    # Step 2: Prepare parameters
    if iterations > 1:
        otp_hex = iteration_results[-2]
        tail_hex = iteration_results[-1]
    else:
        otp_hex = initial_data
        tail_hex = iteration_results[0]
    
    # Step 3: Convert to ASCII bytes
    otp_ascii_bytes = hex_to_ascii_bytes(otp_hex)
    tail_ascii_bytes = hex_to_ascii_bytes(tail_hex)
    
    # Step 4: Prepare results
    result = {
        "platform": "aptos",
        "otp_hex": otp_hex,
        "tail_hex": tail_hex,
        "otp_ascii_bytes": otp_ascii_bytes,
        "tail_ascii_bytes": tail_ascii_bytes,
        "otp_json": json.dumps(otp_ascii_bytes),
        "tail_json": json.dumps(tail_ascii_bytes),
        "aptos_otp_format": f"u8:[{','.join(map(str, otp_ascii_bytes))}]",
        "aptos_tail_format": f"u8:[{','.join(map(str, tail_ascii_bytes))}]"
    }
    
    # Step 5: Verification
    verification_hash = hashlib.sha256(otp_hex.encode('ascii')).hexdigest()
    verification_ok = verification_hash == tail_hex
    
    print("=== Results ===")
    print(f"otp (hex): {otp_hex}")
    print(f"tail (hex): {tail_hex}")
    print()
    print(f"otp (ASCII bytes): {otp_ascii_bytes}")
    print(f"tail (ASCII bytes): {tail_ascii_bytes}")
    print()
    print("=== Aptos CLI Format ===")
    print(f"otp parameter: {result['aptos_otp_format']}")
    print(f"tail parameter: {result['aptos_tail_format']}")
    print()
    print("=== Verification ===")
    print(f"otp_hex as ASCII: {otp_hex.encode('ascii')}")
    print(f"SHA256(otp_hex as ASCII): {verification_hash}")
    print(f"Expected (tail_hex): {tail_hex}")
    print(f"Verification: {'✓ PASS' if verification_ok else '✗ FAIL'}")
    
    result["verification_ok"] = verification_ok
    return result

def complete_payment_workflow_solana(initial_data: str, iterations: int = 3):
    """
    Solana workflow: Uses raw hash bytes converted to hex strings.
    
    Args:
        initial_data: Initial string data
        iterations: Number of SHA256 iterations (default: 3 for otp0->otp1->otp2->tail)
    
    Returns:
        dict: Contains all necessary data for Solana program call
    """
    print(f"=== TinyPay Payment Workflow (Solana) ===")
    print(f"Initial data: {initial_data}")
    print(f"Iterations: {iterations}")
    print()
    
    # Step 1: Perform iterative hashing (Solana style)
    # Start with initial data as bytes
    current = initial_data.encode('utf-8')
    iteration_results = []
    iteration_hex_strings = []
    
    for i in range(iterations):
        # Compute hash and convert to hex string bytes (Solana style)
        hash_result = compute_hash_hex_solana(current)
        iteration_results.append(hash_result)
        
        # Also keep the hex string representation
        hex_str = hash_result.decode('utf-8')
        iteration_hex_strings.append(hex_str)
        
        if i < 3 or i >= iterations - 3:
            print(f"Iteration {i+1}: {hex_str}")
        elif i == 3:
            print("...")
        
        current = hash_result  # Next iteration uses the hex string bytes
    
    print()
    
    # Step 2: Prepare parameters
    # For Solana: otp is second-to-last, tail is last
    if iterations > 1:
        otp_bytes = iteration_results[-2]
        otp_hex = iteration_hex_strings[-2]
        tail_bytes = iteration_results[-1]
        tail_hex = iteration_hex_strings[-1]
    else:
        otp_bytes = initial_data.encode('utf-8')
        otp_hex = initial_data
        tail_bytes = iteration_results[0]
        tail_hex = iteration_hex_strings[0]
    
    # Convert to byte arrays for JSON output
    otp_byte_array = list(otp_bytes)
    tail_byte_array = list(tail_bytes)
    
    # Step 3: Prepare results
    result = {
        "platform": "solana",
        "otp_hex_string": otp_hex,
        "tail_hex_string": tail_hex,
        "otp_bytes": otp_byte_array,
        "tail_bytes": tail_byte_array,
        "otp_json": json.dumps(otp_byte_array),
        "tail_json": json.dumps(tail_byte_array),
        "solana_otp_buffer": f"Buffer.from('{otp_hex}')",
        "solana_tail_buffer": f"Buffer.from('{tail_hex}')"
    }
    
    # Step 4: Verification
    verification_result = compute_hash_hex_solana(otp_bytes)
    verification_hex = verification_result.decode('utf-8')
    verification_ok = verification_hex == tail_hex
    
    print("=== Results ===")
    print(f"otp (hex string): {otp_hex}")
    print(f"tail (hex string): {tail_hex}")
    print()
    print(f"otp (bytes): [{','.join(map(str, otp_byte_array[:20]))}...]" if len(otp_byte_array) > 20 else f"otp (bytes): {otp_byte_array}")
    print(f"tail (bytes): [{','.join(map(str, tail_byte_array[:20]))}...]" if len(tail_byte_array) > 20 else f"tail (bytes): {tail_byte_array}")
    print()
    print("=== Solana TypeScript Format ===")
    print(f"otp: {result['solana_otp_buffer']}")
    print(f"tail: {result['solana_tail_buffer']}")
    print()
    print("=== Verification ===")
    print(f"computeHashHex(otp_bytes): {verification_hex}")
    print(f"Expected (tail_hex_string): {tail_hex}")
    print(f"Verification: {'✓ PASS' if verification_ok else '✗ FAIL'}")
    
    result["verification_ok"] = verification_ok
    
    # Add chain visualization for Solana (typically 3 iterations)
    if iterations <= 5:
        print()
        print("=== OTP Chain Visualization ===")
        print("Usage order (for payments, use from bottom to top):")
        print(f"  Initial: {initial_data}")
        for i in range(len(iteration_hex_strings)):
            if i == len(iteration_hex_strings) - 1:
                print(f"  otp{i} (tail): {iteration_hex_strings[i][:40]}...")
            else:
                print(f"  otp{i}: {iteration_hex_strings[i][:40]}...")
        print()
        print("💡 Payment sequence:")
        for i in range(len(iteration_hex_strings) - 2, -1, -1):
            payment_num = len(iteration_hex_strings) - 1 - i
            print(f"  Payment #{payment_num}: use otp{i}")
    
    return result

def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Complete TinyPay payment workflow for Aptos and Solana",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Aptos workflow with 1000 iterations
  %(prog)s "my_secret_password" --platform aptos -n 1000
  
  # Solana workflow with 3 iterations (default)
  %(prog)s "my_secret_password_12345" --platform solana -n 3
  
  # Output as JSON
  %(prog)s "test_data" --platform solana --json-output
        """
    )
    parser.add_argument("data", help="Initial data string")
    parser.add_argument("-p", "--platform", 
                       choices=["aptos", "solana"], 
                       default="aptos",
                       help="Target platform (default: aptos)")
    parser.add_argument("-n", "--iterations", 
                       type=int, 
                       default=None,
                       help="Number of iterations (default: 1000 for Aptos, 3 for Solana)")
    parser.add_argument("--json-output", 
                       action="store_true",
                       help="Output results as JSON")
    
    args = parser.parse_args()
    
    # Set default iterations based on platform
    if args.iterations is None:
        args.iterations = 1000 if args.platform == "aptos" else 3
    
    # Run appropriate workflow
    if args.platform == "aptos":
        result = complete_payment_workflow_aptos(args.data, args.iterations)
    else:  # solana
        result = complete_payment_workflow_solana(args.data, args.iterations)
    
    if args.json_output:
        print("\n=== JSON Output ===")
        print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
