// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FreelancePayment {
    enum JobStatus { Created, Funded, Submitted, Approved, Disputed, Completed }

    struct Job {
        address client;
        address payable freelancer;
        uint256 amount;
        JobStatus status;
        string description;
    }

    uint256 public jobCount;
    mapping(uint256 => Job) public jobs;

    event JobCreated(uint256 jobId, address client, address freelancer, uint256 amount);
    event JobFunded(uint256 jobId, uint256 amount);
    event WorkSubmitted(uint256 jobId);
    event WorkApproved(uint256 jobId);
    event PaymentReleased(uint256 jobId, uint256 amount);
    event JobDisputed(uint256 jobId);

    modifier onlyClient(uint256 jobId) {
        require(msg.sender == jobs[jobId].client, "Only client can perform this action");
        _;
    }

    modifier onlyFreelancer(uint256 jobId) {
        require(msg.sender == jobs[jobId].freelancer, "Only freelancer can perform this action");
        _;
    }

    function createJob(address payable _freelancer, uint256 _amount, string memory _description) external {
        jobCount++;
        jobs[jobCount] = Job({
            client: msg.sender,
            freelancer: _freelancer,
            amount: _amount,
            status: JobStatus.Created,
            description: _description
        });
        emit JobCreated(jobCount, msg.sender, _freelancer, _amount);
    }

    function fundJob(uint256 jobId) external payable onlyClient(jobId) {
        Job storage job = jobs[jobId];
        require(msg.value == job.amount, "Incorrect amount");
        require(job.status == JobStatus.Created, "Job already funded");
        job.status = JobStatus.Funded;
        emit JobFunded(jobId, msg.value);
    }

    function submitWork(uint256 jobId) external onlyFreelancer(jobId) {
        Job storage job = jobs[jobId];
        require(job.status == JobStatus.Funded, "Job not funded");
        job.status = JobStatus.Submitted;
        emit WorkSubmitted(jobId);
    }

    function approveWork(uint256 jobId) external onlyClient(jobId) {
        Job storage job = jobs[jobId];
        require(job.status == JobStatus.Submitted, "Work not submitted");
        job.status = JobStatus.Approved;
        releasePayment(jobId);
        emit WorkApproved(jobId);
    }

    function releasePayment(uint256 jobId) internal {
        Job storage job = jobs[jobId];
        require(job.status == JobStatus.Approved, "Work not approved");
        job.freelancer.transfer(job.amount);
        job.status = JobStatus.Completed;
        emit PaymentReleased(jobId, job.amount);
    }

    function raiseDispute(uint256 jobId) external {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client || msg.sender == job.freelancer, "Unauthorized");
        require(job.status == JobStatus.Submitted, "Dispute not allowed");
        job.status = JobStatus.Disputed;
        emit JobDisputed(jobId);
    }
}
