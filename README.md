# ContinuousDeploymentPipeline

This is a customized Continuous Delivery pipeline that I developed recently. This project is written in PowerShell.  
Once your CI system generates the builds, this CD automatically deploys your artifactes to the target environment(s).  
This is scalable and can be used for 1 or multiple environments.  

This specific project deploys the following:

* 2 Web apps to AWS Elastic Beanstalk Environments (C# Web API + ASPNET Web App)
* 1 SQL Server DB to AWS RDS
* 2 Windows Services To AWS EC2 Windows Server CORE
* 1 WPF App To EC2
* 1 Windows Service to On Prem Server

## Installation Requirements. 
### Typically these should be automated in your Infrastructure as Code

* Windows Services:
    * Target machines should be configured with AWS CodeDeploy agent

* DB: 
    * The target machine where the scripts will be executed should be in the same VPC as the DB. 
    * Also the instance should have access to the AWS Secret Manager to pull the connection string 

* Elastic Beanstalk:
    * No special requirements


## Usage
Check with your CI provider as this varies by CI. 


## License
[MIT](https://choosealicense.com/licenses/mit/)
