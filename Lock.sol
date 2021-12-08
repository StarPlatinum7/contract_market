// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lock {
    address private owner;
    mapping (address => Record) records;
    address[] users;
    
    bool _enabled = true;
    
    //抵押状态
    struct Record {
        //抵押额度 wei
        uint value;
        //抵押起始时间
        uint64 startTime;
        //总提取次数
        uint index;
    }
    
    struct QueryResult {
        address addr;
        uint lockedAmount;
        uint64 startTime;
        uint withdrawed;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    event USDTLog(address indexed addr, uint amount, string txid);
 

    function lock_540_once(address addr, uint amount, string calldata txidUSDT) public payable {
        require(msg.value > 0,"value cannot be zero");
        require(address(msg.sender) == address(tx.origin),"no cantract");
        require(_enabled,"is disable");
        require(records[addr].value == 0,"lock exist");
        require(msg.value >= amount,"amount false");
        
        records[addr] = Record({
            value : msg.value,
            startTime : uint64(block.timestamp),
            index : users.length
        });
        users.push(addr);
        emit USDTLog(addr, msg.value, txidUSDT);
    }
    
    function querySelf() view public returns(uint, QueryResult memory result) {
        require(records[msg.sender].value > 0,"no records");
        Record storage curRecord = records[msg.sender];
        
        result = QueryResult({
            addr : msg.sender,
            lockedAmount : curRecord.value,
            withdrawed : 0,
            startTime : curRecord.startTime
        });
        return(block.timestamp, result);
    }  
 
    function queryAll(uint start, uint size) view public onlyOwner returns(uint, QueryResult[] memory) {
        require(start + size <= users.length,"overflow");
        QueryResult[] memory result = new QueryResult[](size);
        uint end =start + size;
        for (uint i = start; i < end; i++){
            Record storage curRecord = records[users[i]];
            result[i-start] = QueryResult({
                addr : users[i],
                lockedAmount : curRecord.value,
                withdrawed : 0,
                startTime : curRecord.startTime
            });
        }
        return (block.timestamp,result);
    }
    
    function QueryAny(address addr) view public onlyOwner returns(uint, QueryResult memory result){
        require(records[addr].value > 0, "no record");
        Record storage curRecord = records[addr];
        result = QueryResult({
             addr : addr,
             lockedAmount : curRecord.value,
             withdrawed : 0,
             startTime : curRecord.startTime
        });
        return (block.timestamp, result);
    }
    
    function deleteUser(address addr) private {
        uint index = records[addr].index;
        uint end = users.length - 1;
        if (index < end) {
            users[index] = users[end];
            records[users[end]].index = index; 
        }
        users.pop();
        delete records[addr];
    }
    
    
    function withdraAll() public {
        require(address(msg.sender) == address(tx.origin),"no cantract");
        Record storage curRecord = records[msg.sender];
        uint curTime = block.timestamp;
        uint64 day = uint64(((curTime) / (1 days)) - ((curRecord.startTime) / (1 days)));
        if (day > 540){
            deleteUser(msg.sender);
            payable(msg.sender).transfer(curRecord.value);
        }  
    }
    
    
    function getAllCount() view public onlyOwner returns(uint) {
        return users.length;
    }
    
    function transferLock(address addr) public {
        require(records[addr].value ==0, "lock exist");
        require(addr != msg.sender && addr != address(0), "not self");
        
        users.push(addr);
        records[addr] = records[msg.sender];
        deleteUser(msg.sender);
    }
    
    function transferOnwer(address paramOwner) public onlyOwner {
        if (paramOwner != address(0)){
            owner = paramOwner;
        }
    }
    
    function changeStatus(bool flag) public onlyOwner {
       _enabled = flag;    
    }
    
    modifier onlyOwner() {
        require (msg.sender == owner,"only owner");
        _;
    }
    
    function getOwner() public view returns (address) {
        return owner;
    }
    
    function isEnable() public view returns (bool) {
        return _enabled;
    }
}
