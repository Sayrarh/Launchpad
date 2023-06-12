// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Launchpad is Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    using SafeMath for uint256;
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
        uint256 IDOduration;
        bool isActive;
        uint256 totalAmountRaised;
        uint256 totalTokenIDOClaimed;
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

    mapping(uint256 => mapping(address => bool)) private whitelistedAddresses;

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
    error AddressZero();
    error TxnFailed();
    error TokenAlreadyWhitelisted();
    error ContractNotFullyFunded();
    error EmptyAddress();
    error NotWhiteListed();
    error MaxCapExceeded();
    error TokenAllocationMustBeGreaterThanZero();
    error UserAlreadyWhitelisted();
    error OldAdmin();

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
        uint256 _endTime,
        address[] memory _whiteListedUsers
    ) external whenNotPaused {
        if (_tokenPrice == 0) revert TokenPriceMustBeGreaterThanZero();
        if (_minInvestment == 0)
            revert MinimumInvestmentMustBeGreaterThanZero();
        if (_maxInvestment < _minInvestment)
            revert MaxInvestmentMustBeGreaterOrEqualToMinInvestment();
        if (_maxInvestment > _maxCap)
            revert MaxCapMustBeGreaterOrEqualToMaxInvestment();

        if (_whiteListedUsers.length == 0) revert EmptyAddress();

        projectsCurrentId = projectsCurrentId + 1;

        for (uint256 i; i < _whiteListedUsers.length; i++) {
            address user = _whiteListedUsers[i];
            if (user == address(0)) revert AddressZero();
            whitelistedAddresses[projectsCurrentId][user] = true;
        }

        IDOProject storage project = projects[projectsCurrentId];

        if (tokenListed[address(_token)] == true)
            revert TokenAlreadyWhitelisted();

        project.projectOwner = msg.sender;
        project.token = _token;
        project.tokenPrice = _tokenPrice;
        project.minInvestment = _minInvestment;
        project.maxInvestment = _maxInvestment;
        project.maxCap = _maxCap;
        project.IDOduration = (_endTime * 1 minutes).add(block.timestamp);
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
            _endTime
        );
    }

    function isWhitelisted(
        uint256 _projectId,
        address _address
    ) private view returns (bool) {
        return whitelistedAddresses[_projectId][_address];
    }

    function invest(uint256 _projectId) external payable whenNotPaused {
        if (_projectId > projectsCurrentId || _projectId == 0)
            revert InvalidProjectID();

        IDOProject storage project = projects[_projectId];

        if (isWhitelisted(_projectId, msg.sender) == false)
            revert NotWhiteListed();
        if (project.isActive == false) revert ProjectNotActive();

        if (IERC20(project.token).balanceOf(address(this)) < project.maxCap)
            revert ContractNotFullyFunded();

        if (block.timestamp > project.IDOduration) revert ProjectEnded();

        if (msg.value < project.minInvestment)
            revert InvestmentAmtBelowMinimum();
        if (
            (projectInvestments[_projectId][msg.sender].add(msg.value)) >
            project.maxInvestment
        ) revert InvestmentAmtExceedsMaximum();

        uint256 investmentAmount = msg.value;

        // Calculate token allocation
        uint256 tokenAllocation = (investmentAmount / project.tokenPrice).mul(
            1e18
        );
        if (tokenAllocation == 0) revert TokenAllocationMustBeGreaterThanZero();

        // Ensure token allocation doesn't exceed the maximum cap
        if (tokenAllocation > project.maxCap) revert MaxCapExceeded();

        // Deduct the token allocation from the total token supply
        project.maxCap = project.maxCap.sub(tokenAllocation);

        projectInvestments[_projectId][msg.sender] = projectInvestments[
            _projectId
        ][msg.sender].add(investmentAmount);

        allocation[_projectId][msg.sender] = allocation[_projectId][msg.sender]
            .add(tokenAllocation);

        project.totalTokenIDOClaimed = project.totalTokenIDOClaimed.add(
            tokenAllocation
        );

        // Transfer the allocated tokens to the participant.
        IERC20(project.token).safeTransfer(_msgSender(), tokenAllocation);
        project.totalAmountRaised = project.totalAmountRaised.add(
            investmentAmount
        );

        bool alreadyInvestor = false;
        for (uint256 i; i < project.projectInvestors.length; i++) {
            if (project.projectInvestors[i] == msg.sender) {
                alreadyInvestor = true;
                break;
            }
        }

        if (!alreadyInvestor) {
            project.projectInvestors.push(msg.sender);
        }
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

    function AddUserForAParticularProject(
        uint256 _projectId,
        address _user
    ) external whenNotPaused {
        if (_projectId > projectsCurrentId || _projectId == 0)
            revert InvalidProjectID();

        IDOProject storage project = projects[_projectId];
        if (msg.sender != project.projectOwner) revert NotProjectOwner();
        if (_user == address(0)) revert AddressZero();
        if (whitelistedAddresses[_projectId][_user] == true)
            revert UserAlreadyWhitelisted();

        whitelistedAddresses[_projectId][_user] = true;
        project.whiteListedAddresses.push(_user);
    }

    //
    /**
     * @dev alternative to Deposit IDO token for investment
     */
    function depositIDOTokens(
        uint256 _projectId,
        uint256 amount
    ) external whenNotPaused {
        if (_projectId > projectsCurrentId || _projectId == 0)
            revert InvalidProjectID();

        IDOProject storage project = projects[_projectId];
        if (msg.sender != project.projectOwner) revert NotProjectOwner();

        IERC20(project.token).safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );
    }

    /**
     * @dev function allows the IDO project owner to withdraw the raised funds after the listing project period ends
     */
    function withdrawAmountRaised(
        uint256 _projectID
    ) external payable whenNotPaused nonReentrant {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();
        IDOProject storage project = projects[_projectID];

        if (msg.sender != project.projectOwner) revert NotProjectOwner();
        if (project.withdrawn == true) revert AlreadyWithdrawn();

        if (block.timestamp < project.IDOduration)
            revert ProjectStillInProgress();
        uint256 amountRaised = project.totalAmountRaised;

        // project.totalAmountRaised = 0;
        project.withdrawn = true;
        (bool success, ) = payable(msg.sender).call{value: amountRaised}("");
        if (!success) revert TxnFailed();
    }

    function changeLaunchPadAdmin(address _newAdmin) external whenNotPaused {
        if (msg.sender != launchPadadmin) revert NotLaunchPadAdmin();
        if (_newAdmin == address(0)) revert AddressZero();
        if (_newAdmin == launchPadadmin) revert OldAdmin();
        launchPadadmin = _newAdmin;
    }

    function getIDOTokenBalanceInLaunchPad(
        uint256 projectId
    ) public view returns (uint256) {
        if (projectId > projectsCurrentId || projectId == 0)
            revert InvalidProjectID();

        IDOProject memory project = projects[projectId];
        return IERC20(project.token).balanceOf(address(this));
    }

    function getTokenLeftForAParticularIDO(
        uint256 projectId
    ) public view returns (uint256) {
        if (projectId > projectsCurrentId || projectId == 0)
            revert InvalidProjectID();

        IDOProject memory project = projects[projectId];
        uint256 tokenLeft = project.maxCap.sub(project.totalTokenIDOClaimed);

        return tokenLeft;
    }

    function sweep(uint256 _projectID, address to) external whenNotPaused {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();
        IDOProject storage project = projects[_projectID];

        if (msg.sender != project.projectOwner) revert NotProjectOwner();
        if (to == address(0)) revert AddressZero();

        if (block.timestamp < project.IDOduration)
            revert ProjectStillInProgress();

        uint256 balance = getIDOTokenBalanceInLaunchPad(_projectID);
        IERC20(project.token).safeTransfer(to, balance);

        emit Swept(to, balance);
    }

    function getInvestorsForAParticularProject(
        uint256 _projectID
    ) external view returns (address[] memory) {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();

        IDOProject memory project = projects[_projectID];
        return project.projectInvestors;
    }

    function getUserInvestmentForAnIDOInCELO(
        uint256 _projectID,
        address _i
    ) external view returns (uint256) {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();
        return projectInvestments[_projectID][_i];
    }

    function getAUserAllocationForAProject(
        uint256 _projectID,
        address userAddr
    ) external view returns (uint256) {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();

        return allocation[_projectID][userAddr];
    }

    function cancelIDOProject(uint256 _projectId) external {
        if (msg.sender != launchPadadmin) revert NotLaunchPadAdmin();
        if (_projectId > projectsCurrentId || _projectId == 0)
            revert InvalidProjectID();

        IDOProject storage project = projects[_projectId];
        project.isActive = false;
        project.IDOduration = 0;
        address to = project.projectOwner;

        uint256 balance = getIDOTokenBalanceInLaunchPad(_projectId);
        IERC20(project.token).safeTransfer(to, balance);
    }

    function getProjectDetails(
        uint256 _projectID
    ) external view returns (IDOProject memory) {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();
        return projects[_projectID];
    }

    function getProjectPrice(
        uint256 _projectID
    ) external view returns (uint256) {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();

        IDOProject memory project = projects[_projectID];
        return project.tokenPrice;
    }

    function getProjectMaxCap(
        uint256 _projectID
    ) external view returns (uint256) {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();

        IDOProject memory project = projects[_projectID];
        return project.maxCap;
    }

    function getProjectTotalAmtRaised(
        uint256 _projectID
    ) external view returns (uint256) {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();

        IDOProject memory project = projects[_projectID];
        return project.totalAmountRaised;
    }

    function getProjectTotalTokenIDOClaimed(
        uint256 _projectID
    ) external view returns (uint256) {
        if (_projectID > projectsCurrentId || _projectID == 0)
            revert InvalidProjectID();

        IDOProject memory project = projects[_projectID];
        return project.totalTokenIDOClaimed;
    }

    function getTimeLeftForAParticularProject(
        uint256 projectId
    ) public view returns (uint256) {
        if (projectId > projectsCurrentId || projectId == 0)
            revert InvalidProjectID();

        IDOProject storage project = projects[projectId];

        if (block.timestamp >= project.IDOduration) {
            return 0; // IDOProject has ended
        } else {
            uint256 timeLeftInSeconds = project.IDOduration - block.timestamp;
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
}
