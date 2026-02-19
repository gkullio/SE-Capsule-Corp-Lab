### Prerequisites:

You will need an .p12 API Certificate from Distibuted Cloud and store it in the same directory as the root main.tf file.
Use the following command to save the p12 cert password to a local varibabe:
export VES_P12_PASSWORD="p12 cert password"

You will need a service principle from Azure Active Directory
client_id
tenant_id
client_secret
subscription_id

---

### Capsule Corp Lab details for deployment:

This deploys 1 CE and 1 Ubuntu App Server / Client in 2 regions (US, India) 

| CE Site       | Region      |
|---------------|-------------|
| Frieza Force  | India       |
| West City     | US          |



| App | IP Space |
|-----|----------|
| West City apps | 10.245.0.4 |
| Frieza Force apps | 172.20.0.4 |


| Region | Default Gateway IP |
|--------|-------------------|
| West City         | 10.245.1.10 |


---

Main lab page (After deployument, access the lab environment using the following URL):

https://${var.se_name}-lab-main.amer-ent.f5demos.com

Internal Lab Page:

https://${var.se_name}-lab-int.amer-ent.f5demos.com