# Continuous Deployment Pipeline

This is a customized Continuous Delivery pipeline that I developed to automate deployments to AWS Cloud. The deployment instructions are written in PowerShell.
It deploys to AWS RDS, Apps and Services. Uses AWS CodeDeploy to move the deployment scripts and executables to EC2

Once your CI system generates the builds, this CD automatically deploys your artifactes to the target environment(s).  
This is scalable and can be used for 1 or multiple environments.  

This specific project deploys the following:


* 1 SQL Server DB to AWS RDS
* 2 Windows Services To AWS EC2 Windows Server CORE
* 1 WPF App To EC2
* 1 Windows Service to On Prem Server
* 2 Web apps to AWS Elastic Beanstalk Environments (C# Web API + ASP.NET Web App)
* 1 Serverless Lambda (C# NETCORE)

## Installation Requirements. 

* EC2:
    * Target machines should have the AWS CodeDeploy agent installed and running

* DB: 
    * The target machine where the scripts will be executed should be in the same VPC as the DB. 
    * Also the instance should have access to the AWS Secret Manager to pull the connection string 

* Elastic Beanstalk:
    * No special requirements

* Lambda:
    * No special requirements


## License
[MIT](https://choosealicense.com/licenses/mit/)
