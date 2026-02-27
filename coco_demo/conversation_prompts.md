# Conversation Prompts - Reconciliation 360 dbt Project

## Prompt 1: Project Setup
```
Please set up a proper empty DBT project using dbt skill in my coco_demo repo please can you do that?
```

## Prompt 2: Database Change & Data Model Context
```
Okay I do want to change this slightly and I want to work I want to use DPAPI_REPLICA_DB

I believe that this is the data model 

# Reconciliation Management System - Data Model

## Overview

This is a **Financial Reconciliation Management System** designed for enterprise account reconciliation, certification workflows, and variance analysis. The system manages the full lifecycle of financial reconciliations across multiple organizational entities, periods, and currencies.

## Domain Description

### Purpose
The system enables organizations to:
- **Reconcile accounts** - Match and verify financial balances across systems
- **Certify periods** - Track sign-off workflows for financial close
- **Analyze variances** - Identify and explain differences between expected and actual values
- **Manage hierarchies** - Support multi-entity consolidation and reporting

### Key Business Processes
1. **Period Management** - Define reconciliation periods (monthly, quarterly, annual)
2. **Assignment Workflow** - Assign reconciliations to users with role-based access
3. **Item Tracking** - Track individual line items and their reconciliation status
4. **Certification** - Multi-level approval and certification workflows
5. **Variance Analysis** - Track and explain variances over time
6. **Consolidation** - Roll up results across organizational hierarchies

[... full ERD and table descriptions provided ...]

I want to create a DBT model that create a customer 360 view of this can you help me do this and create semantic views that can help me talk to my data when I create an agent later on? 

Also swich to ACCOUNTADMIN as the role for now please
```

## Prompt 3: Exploration Queries Request
```
Can you create a .sql that is helpful queries for this data model for someone trying to get an understanding of what just created?
```

## Prompt 4: Privilege Error
```
CREATE DBT PROJECT "DBAPI_REPLICA_DB"."DBT_PROJECTS"."COCO_DBT_PROJECT_TEST" FROM $$snow://workspace/USER$JDEMLOW.PUBLIC."coco_demo"/versions/live/coco_demo$$ DEFAULT_TARGET = 'dev' DBT_VERSION = '1.9.4'

Error: SQL access control error:
Insufficient privileges to operate on schema 'DBT_PROJECTS'.

When I try to use the UI?
```

## Prompt 5: Semantic View Correction
```
I think one think I can see wrong is that we didn't use the semantic view syntax and we don't have the package maybe from snowflake labs that supports semantic views inside of dbt while the semantic model is great this isn't quick correct
```

## Prompt 6: Skill Usage Suggestion
```
If you are struggling make sure you invoke the dbt skill and the semantic skill to help you get there as you have if you need to do any optimizations here this sounds amazing thank you
```

## Prompt 7: Notebook Cells Issue
```
I don't see the cells being added though and it's not connectedto to a service is it?
```

## Prompt 8: Documentation Request
```
Can you put in a .md all the prompts I have sent you in this thread
```
