const MyContract = artifacts.require("MyContract");

contract("MyContract", accounts => {
  it("should do something", async () => {
    const instance = await MyContract.deployed();
    // Your test code here
  });
});
