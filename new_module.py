import os

def generate_usp(name, digitals, analogs, serials):
    rows = max(len(digitals), len(analogs), len(serials))
    
    usp = f"""/*******************************************************************************************
  AUTHOR: James Ashcraft
  VERSION: 1.0.0
*******************************************************************************************/

#SYMBOL_NAME      "{name}"
#DEFAULT_VOLATILE
#ENABLE_STACK_CHECKING
#ENABLE_TRACE

// ------ INPUTS --------
"""
    for i, d in enumerate(digitals):
        usp += f"DIGITAL_INPUT   {d}_b; // Row {i+1}\n"
    for i, a in enumerate(analogs):
        usp += f"ANALOG_INPUT    {a}_n; // Row {i+1}\n"
    for i, s in enumerate(serials):
        usp += f"STRING_INPUT    {s}_s[255]; // Row {i+1}\n"

    usp += "\n// ------ OUTPUTS --------\n"
    # Logic for alignment skips would go here in a full script
    usp += "\nFunction Main()\n{\n}\n"
    
    with open(f"{name}.usp", "w") as f:
        f.write(usp)

if __name__ == "__main__":
    print("SIMPL+ Module Generator")
    name = input("Module Name: ")
    generate_usp(name, ["Power_On", "Power_Off"], ["Set_Volume"], ["From_Device"])
    print(f"Generated {name}.usp")
