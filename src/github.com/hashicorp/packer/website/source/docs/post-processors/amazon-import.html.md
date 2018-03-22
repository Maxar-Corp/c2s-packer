---
description: |
    The Packer Amazon Import post-processor takes an OVA artifact from various
    builders and imports it to an AMI available to Amazon Web Services EC2.
layout: docs
page_title: 'Amazon Import - Post-Processors'
sidebar_current: 'docs-post-processors-amazon-import'
---

# Amazon Import Post-Processor

Type: `amazon-import`

The Packer Amazon Import post-processor takes an OVA artifact from various builders and imports it to an AMI available to Amazon Web Services EC2.

~&gt; This post-processor is for advanced users. It depends on specific IAM roles inside AWS and is best used with images that operate with the EC2 configuration model (eg, cloud-init for Linux systems). Please ensure you read the [prerequisites for import](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/VMImportPrerequisites.html) before using this post-processor.

## How Does it Work?

The import process operates making a temporary copy of the OVA to an S3 bucket, and calling an import task in EC2 on the OVA file. Once completed, an AMI is returned containing the converted virtual machine. The temporary OVA copy in S3 can be discarded after the import is complete.

The import process itself run by AWS includes modifications to the image uploaded, to allow it to boot and operate in the AWS EC2 environment. However, not all modifications required to make the machine run well in EC2 are performed. Take care around console output from the machine, as debugging can be very difficult without it. You may also want to include tools suitable for instances in EC2 such as `cloud-init` for Linux.

Further information about the import process can be found in AWS's [EC2 Import/Export Instance documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instances_of_your_vm.html).

## Configuration

There are some configuration options available for the post-processor. They are
segmented below into two categories: required and optional parameters.
Within each category, the available configuration keys are alphabetized.

Required:

-   `access_key` (string) - The access key used to communicate with AWS. [Learn
    how to set this.](/docs/builders/amazon.html#specifying-amazon-credentials)

-   `region` (string) - The name of the region, such as `us-east-1` in which to upload the OVA file to S3 and create the AMI. A list of valid regions can be obtained with AWS CLI tools or by consulting the AWS website.

-   `s3_bucket_name` (string) - The name of the S3 bucket where the OVA file will be copied to for import. This bucket must exist when the post-processor is run.

-   `secret_key` (string) - The secret key used to communicate with AWS. [Learn
    how to set this.](/docs/builders/amazon.html#specifying-amazon-credentials)

Optional:

-   `ami_description` (string) - The description to set for the resulting
    imported AMI. By default this description is generated by the AMI import
    process.

-   `ami_groups` (array of strings) - A list of groups that have access to
    launch the imported AMI. By default no groups have permission to launch the
    AMI. `all` will make the AMI publicly accessible. AWS currently doesn't
    accept any value other than "all".

-   `ami_name` (string) - The name of the ami within the console. If not
    specified, this will default to something like `ami-import-sfwerwf`.
    Please note, specifying this option will result in a slightly longer
    execution time.

-   `ami_users` (array of strings) - A list of account IDs that have access to
    launch the imported AMI. By default no additional users other than the user
    importing the AMI has permission to launch it.

-   `license_type` (string) - The license type to be used for the Amazon Machine
    Image (AMI) after importing. Valid values: `AWS` or `BYOL` (default).
    For more details regarding licensing, see
    [Prerequisites](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/VMImportPrerequisites.html)
    in the VM Import/Export User Guide.

-   `mfa_code` (string) - The MFA [TOTP](https://en.wikipedia.org/wiki/Time-based_One-time_Password_Algorithm)
    code. This should probably be a user variable since it changes all the time.

-   `role_name` (string) - The name of the role to use when not using the default role, 'vmimport'

-   `s3_key_name` (string) - The name of the key in `s3_bucket_name` where the
    OVA file will be copied to for import. If not specified, this will default
    to "packer-import-{{timestamp}}.ova". This key (ie, the uploaded OVA) will
    be removed after import, unless `skip_clean` is `true`.

-   `skip_clean` (boolean) - Whether we should skip removing the OVA file uploaded to S3 after the
    import process has completed. "true" means that we should leave it in the S3 bucket, "false" means to clean it out. Defaults to `false`.

-   `tags` (object of key/value strings) - Tags applied to the created AMI and
    relevant snapshots.

-   `token` (string) - The access token to use. This is different from the
    access key and secret key. If you're not sure what this is, then you
    probably don't need it. This will also be read from the `AWS_SESSION_TOKEN`
    environmental variable.

## Basic Example

Here is a basic example. This assumes that the builder has produced an OVA artifact for us to work with, and IAM roles for import exist in the AWS account being imported into.

``` json
{
  "type": "amazon-import",
  "access_key": "YOUR KEY HERE",
  "secret_key": "YOUR SECRET KEY HERE",
  "region": "us-east-1",
  "s3_bucket_name": "importbucket",
  "license_type": "BYOL",
  "tags": {
    "Description": "packer amazon-import {{timestamp}}"
  }
}
```

## VMWare Example

This is an example that uses `vmware-iso` builder and exports the `.ova` file using ovftool.

``` json
"post-processors" : [
     [
     {
      "type": "shell-local",
      "inline": [ "/usr/bin/ovftool <packer-output-directory>/<vmware-name>.vmx <packer-output-directory>/<vmware-name>.ova" ]
     },
     {
         "files": [
           "<packer-output-directory>/<vmware-name>.ova"
         ],
         "type": "artifice"
     },
     {
      "type": "amazon-import",
      "access_key": "YOUR KEY HERE",
      "secret_key": "YOUR SECRET KEY HERE",
      "region": "us-east-1",
      "s3_bucket_name": "importbucket",
      "license_type": "BYOL",
      "tags": {
        "Description": "packer amazon-import {{timestamp}}"
      }
     }
    ]
  ]
```

-&gt; **Note:** Packer can also read the access key and secret access key from
environmental variables. See the configuration reference in the section above
for more information on what environmental variables Packer will look for.

This will take the OVA generated by a builder and upload it to S3. In this case, an existing bucket called `importbucket` in the `us-east-1` region will be where the copy is placed. The key name of the copy will be a default name generated by packer.

Once uploaded, the import process will start, creating an AMI in the "us-east-1" region with a "Description" tag applied to both the AMI and the snapshots associated with it. Note: the import process does not allow you to name the AMI, the name is automatically generated by AWS.

After tagging is completed, the OVA uploaded to S3 will be removed.