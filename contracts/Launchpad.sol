// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Launchpad is Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    ///////////////EVENTS//////////////////
    /**
     * @dev Emits when a new project is listed on the launchpad with its details
     */
    event ProjectListed(
        uint256 indexed projectId,
        address indexed projectOwner,
        address indexed token,
        uint256 tokenPrice,
        uint256 minInvestment,
        uint256 maxInvestment,
        uint256 maxCap, //IDO totalsupply
        uint256 startTimeInMinutes,
        uint256 endTimeInMinutes
    );

    /**
     * @dev Emits when an investor/project participant makes an investment/contribution in a particular IDO project
     */
    event InvestmentMade(
        uint256 indexed projectId,
        address indexed investor,
        uint256 amountInvested
    );

    /**
     * @dev Emits when the allocation of tokens is updated for a participant in a particular IDO project
     */
    event AllocationUpdated(address indexed participant, uint256 allocation);

    /**
     * @dev Emits when a participant claims their allocated tokens
     */
    event TokenClaimed(address sender, uint256 amountToclaim);

    event Swept(address to, uint256 value);

    /////////////////STATE VARIABLES///////////////////
    address public launchPadadmin;

    uint256 projectsCurrentId;

    struct IDOProject {
        address projectOwner;
        IERC20 token;
        uint256 tokenPrice;
        uint256 minInvestment;
        uint256 maxInvestment;
        uint256 maxCap; //IDO totalSupply
        uint256 durationInMinutes;
        bool isActive;
        uint256 totalAmountRaised;
        address[] whiteListedAddresses;
        address[] projectInvestors;
        bool withdrawn;
    }

    //Tracks the investment amount of each participant for a specific project
    mapping(uint256 => mapping(address => uint256)) projectInvestments;
    //Keeps track of whitelisted tokens for the launchpad
    mapping(address => bool) tokenListed;
    //tracks whether a participant has already claimed their allocated tokens
    mapping(address => bool) claimed;

    // The allocation of a particular IDO for each participant
    mapping(uint256 => mapping(address => uint256)) allocation;
    mapping(uint256 => IDOProject) projects;

    ///////////////ERRORS//////////////////
    error NotLaunchPadAdmin();
    error TokenPriceMustBeGreaterThanZero();
    error MinimumInvestmentMustBeGreaterThanZero();
    error MaxInvestmentMustBeGreaterOrEqualToMinInvestment();
    error MaxCapMustBeGreaterOrEqualToMaxInvestment();
    error EndTimeMustBeInFuture();
    error InvalidProjectID();
    error ProjectNotActive();
    error InvestmentAmtBelowMinimum();
    error InvestmentAmtExceedsMaximum();
    error ProjectEnded();
    error NotProjectOwner();
    error AlreadyWithdrawn();
    error ProjectStillInProgress();
    error AlreadyClaimed();
    error NoInvestment();
    error AddressZero();
    error TxnFailed();
    error TokenAlreadyWhitelisted();
    error ContractNotFullyFunded();
    error EmptyAddress();
    error NotWhiteListed();
    error InsufficientAmount();
    error InsufficientBalance();
    error MaxCapExceeded();

    constructor() {
        launchPadadmin = msg.sender;
    }

    /**
     * @dev function to list a new project with its details
     */

    function listProject(
        IERC20 _token,
        uint256 _tokenPrice,
        uint256 _minInvestment,
        uint256 _maxInvestment,
        uint256 _maxCap,
        uint256 _startTime,
        uint256 _endTime,
        address[] memory _whiteListedUsers
    ) external {
        if (_tokenPrice == 0) revert TokenPriceMustBeGreaterThanZero();
        if (_minInvestment == 0)
            revert MinimumInvestmentMustBeGreaterThanZero();
        if (_maxInvestment < _minInvestment)
            revert MaxInvestmentMustBeGreaterOrEqualToMinInvestment();
        if (_maxInvestment > _maxCap)
            revert MaxCapMustBeGreaterOrEqualToMaxInvestment();

        if (_whiteListedUsers.length == 0) revert EmptyAddress();

        for (uint256 i; i < _whiteListedUsers.length; i++) {
            address user = _whiteListedUsers[i];
            if (user == address(0)) revert AddressZero();
        }

        if (block.timestamp > ((_endTime * 1 minutes) + block.timestamp))
            revert EndTimeMustBeInFuture();

        projectsCurrentId = projectsCurrentId + 1;

        IDOProject storage project = projects[projectsCurrentId];

        if (tokenListed[address(_token)] == true)
            revert TokenAlreadyWhitelisted();

        project.projectOwner = msg.sender;
        project.token = _token;
        project.tokenPrice = _tokenPrice;
        project.minInvestment = _minInvestment;
        project.maxInvestment = _maxInvestment;
        project.maxCap = _maxCap;
        project.durationInMinutes = (_endTime * 1 minutes) + block.timestamp;
        project.whiteListedAddresses = _whiteListedUsers;
        project.isActive = true;

        tokenListed[address(_token)] = true;

        emit ProjectListed(
            projectsCurrentId,
            msg.sender,
            address(_token),
            _tokenPrice,
            _minInvestment,
            _maxInvestment,
            _maxCap,
            _startTime,
            _endTime
        );
    }

    function isWhitelisted(
        uint256 _projectId,
        address _user
    ) private view returns (bool) {
        IDOProject storage project = projects[_projectId];

        for (uint256 i; i < project.whiteListedAddresses.length; i++) {
            if (project.whiteListedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev function for whitelisted investors to invest in a particular IDO project
     */
    function invest(
        uint256 _projectId
    ) external payable whenNotPaused nonReentrant {
        if (_projectId > projectsCurrentId || _projectId == 0)
            revert InvalidProjectID();

        IDOProject storage project = projects[_projectId];

        if (isWhitelisted(_projectId, msg.sender) == false)
            revert NotWhiteListed();
        if (project.isActive == false) revert ProjectNotActive();

        if (IERC20(project.token).balanceOf(address(this)) < project.maxCap)
            revert ContractNotFullyFunded();

        if (block.timestamp > project.durationInMinutes) revert ProjectEnded();

        if (msg.value < project.minInvestment)
            revert InvestmentAmtBelowMinimum();
        if (
            (projectInvestments[_projectId][msg.sender] + msg.value) >
            project.maxInvestment
        ) revert InvestmentAmtExceedsMaximum();
        //  uint256 amount = msg.value;
        //  uint256 IDOBalance = getTokenBalForAParticul(_projectId);
        if (project.totalAmountRaised + msg.value > project.maxCap)
            revert MaxCapExceeded();

        // if (IDOBalance < amount) revert InsufficientBalance();

        //uint256 purchaseTokenAmount = amount * project.tokenPrice / (10 ** 18);

        projectInvestments[_projectId][msg.sender] =
            projectInvestments[_projectId][msg.sender] +
            msg.value;

        project.totalAmountRaised = project.totalAmountRaised + msg.value;
        project.projectInvestors.push(msg.sender);

        updateAllocation(_projectId);

        emit InvestmentMade(
            _projectId,
            msg.sender,
            projectInvestments[_projectId][msg.sender]
        );
    }

    /**
     * @dev Pause the sale
     */
    function pause() external {
        if (msg.sender != launchPadadmin) revert NotLaunchPadAdmin();
        super._pause();
    }

    /**
     * @dev Unpause the sale
     */
    function unpause() external {
        if (msg.sender != launchPadadmin) revert NotLaunchPadAdmin();
        super._unpause();
    }

    //function sweep
    function backListUserForAParticularProject(
        uint256 _projectId,
        address _user
    ) external {
        if (_projectId > projectsCurrentId || _projectId == 0)
            revert InvalidProjectID();

        IDOProject storage project = projects[_projectId];
        if (msg.sender != project.projectOwner) revert NotProjectOwner();

        project.whiteListedAddresses.push(_user);
    }

    //["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]

    /**
     * @dev Deposit IDO token to the sale contract
     */
    function depositTokens(
        uint256 _projectId,
        uint256 amount
    ) external whenNotPaused {
        if (_projectId > projectsCurrentId || _projectId == 0)
            revert InvalidProjectID();

        IDOProject storage project = projects[_projectId];
        if (msg.sender != project.projectOwner) revert NotProjectOwner();
        if (amount < project.maxCap) {
            revert InsufficientAmount();
        }
        IERC20(project.token).safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );
    }

    /**
     * @dev function calculates and updates the token allocation for each participant based on their contributions in a particular IDO project
     */
    function updateAllocation(uint256 _projectId) private {
        IDOProject storage project = projects[_projectId];
        uint256 totalRaised = project.totalAmountRaised;

        for (uint256 i; i < project.whiteListedAddresses.length; i++) {
            uint256 userContribution = projectInvestments[_projectId][
                project.whiteListedAddresses[i]
            ];
            allocation[_projectId][project.whiteListedAddresses[i]] =
                (userContribution / totalRaised) *
                project.maxCap;
        }

        emit AllocationUpdated(msg.sender, allocation[_projectId][msg.sender]);
    }

    /**
     * @dev function for participants to claim their allocated tokens after the project ends
     */

    function claimAllocation(uint256 _projectID) external whenNotPaused {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();
        IDOProject storage project = projects[_projectID];

        if (block.timestamp < project.durationInMinutes)
            revert ProjectStillInProgress();
        if (projectInvestments[_projectID][msg.sender] == 0)
            revert NoInvestment();
        if (claimed[msg.sender] == true) revert AlreadyClaimed();

        uint256 amountToclaim = allocation[_projectID][msg.sender];

        claimed[msg.sender] = true;

        //// Transfer the allocated tokens to the participant.
        IERC20(project.token).safeTransfer(_msgSender(), amountToclaim);

        emit TokenClaimed(_msgSender(), amountToclaim);
    }

    /**
     * @dev function allows the IDO project owner to withdraw the raised funds after the listing project period ends
     */
    function withdrawAmountRaised(uint256 _projectID) external payable {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();
        IDOProject storage project = projects[_projectID];

        if (msg.sender != project.projectOwner) revert NotProjectOwner();
        if (project.withdrawn == true) revert AlreadyWithdrawn();

        if (block.timestamp < project.durationInMinutes)
            revert ProjectStillInProgress();
        uint256 amountRaised = project.totalAmountRaised;

        // project.totalAmountRaised = 0;
        project.withdrawn = true;
        (bool success, ) = payable(msg.sender).call{value: amountRaised}("");
        if (!success) revert TxnFailed();
    }

    function changeLaunchPadAdmin(address _newAdmin) external whenNotPaused {
        if (msg.sender != launchPadadmin) revert NotLaunchPadAdmin();
        launchPadadmin = _newAdmin;
    }

    function getTokenBalForAParticul(
        uint256 projectId
    ) private view returns (uint256) {
        if (projectId > projectsCurrentId || projectId == 0)
            revert InvalidProjectID();

        IDOProject memory project = projects[projectId];
        return IERC20(project.token).balanceOf(address(this));
    }

    function sweep(uint256 _projectID, address to) external {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();
        if (to == address(0)) revert AddressZero();
        IDOProject storage project = projects[_projectID];

        if (msg.sender != project.projectOwner) revert NotProjectOwner();
        if (block.timestamp < project.durationInMinutes)
            revert ProjectStillInProgress();

        uint256 balance = getTokenBalForAParticul(_projectID);
        IERC20(project.token).safeTransfer(to, balance);

        emit Swept(to, balance);
    }

    function returnInvestorsForAParticularProject(
        uint256 _projectID
    ) external view returns (address[] memory) {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();

        IDOProject memory project = projects[_projectID];
        return project.projectInvestors;
    }

    function getUserInvestmentForAnIDOInCELO(
        uint256 _projectID,
        uint256 _i
    ) external view returns (uint256) {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();

        IDOProject memory project = projects[_projectID];
        return projectInvestments[_projectID][project.projectInvestors[_i]];
    }

    function getAUserAllocationForAProject(
        uint256 _projectID,
        address userAddr
    ) external view returns (uint256) {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();

        return allocation[_projectID][userAddr];
    }

    function cancelProject(uint256 _projectId) external {
        if (msg.sender != launchPadadmin) revert NotLaunchPadAdmin();
        if (_projectId > projectsCurrentId || _projectId == 0)
            revert InvalidProjectID();

        IDOProject storage project = projects[_projectId];
        project.isActive = false;
    }

    function getProjectDetails(
        uint256 _projectID
    ) external view returns (IDOProject memory) {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();
        return projects[_projectID];
    }

    function getTimeLeftForAParticularProject(
        uint256 projectId
    ) public view returns (uint256) {
        if (projectId > projectsCurrentId || projectId == 0)
            revert InvalidProjectID();

        IDOProject memory project = projects[projectId];

        if (block.timestamp >= project.durationInMinutes) {
            return 0; // IDOProject has ended
        } else {
            uint256 timeLeftInSeconds = project.durationInMinutes -
                block.timestamp;
            uint256 timeLeftInMinutes = timeLeftInSeconds / 60; // Convert seconds to minutes
            return timeLeftInMinutes;
        }
    }

    function getCurrentProjectID() external view returns (uint256) {
        return projectsCurrentId;
    }

    ///@dev function to get contract balance
    function getContractBal() external view returns (uint256) {
        return address(this).balance;
    }

    function getTotalInvestorsForAParticularProject(
        uint256 projectId
    ) external view returns (uint256) {
        if (projectId > projectsCurrentId || projectId == 0)
            revert InvalidProjectID();

        IDOProject memory project = projects[projectId];
        return project.projectInvestors.length;
    }

    receive() external payable {}
}
