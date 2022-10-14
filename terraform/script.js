#!/usr/bin/env ts-node
import {TerraformGenerator} from 'terraform-generator';
import * as fs from "fs";
import * as yaml from 'js-yaml';
import Glob from 'glob';
import _ from "lodash"


function addProviders(supportedPlatforms, t) {
    for (const i of supportedPlatforms) {
        switch (i) {
            case 'iaas:aws':
                t.provider('aws');
                break;
            case 'iaas:azure':
                t.provider('azurerm', {'features': {}});
                break;
            case 'iaas:gcp':
                t.provider('google');
                break;
            default:
                break;
        }
    }
}


function getResourceId(idStr, t) {
    const blocks = t.getBlocks();
    const [resourceType, resourceName, id] = idStr.split(".")
    for (const i of blocks) {
        if (i.type === resourceType && i.name === resourceName) {
            return i.attr(id)
        }
    }
}

function addResources(resource, resourceName, resourceArgs, t) {
    if (!_.isEmpty(resourceArgs)) {
        for (const arg in resourceArgs) {
            const value = resourceArgs[arg];
            if (_.isString(value)) {
                if (value.startsWith("aws_") || value.startsWith("azurerm_") || value.startsWith("google_")) {
                    resourceArgs[arg] = getResourceId(value, t)
                }
            }
        }
    }
    t.resource(resource, resourceName, resourceArgs)
}

function generateTerraformFiles(atomicTest) {
    const tfg = new TerraformGenerator({
        required_version: '>= 0.12'
    });
    addProviders(atomicTest.supported_platforms, tfg)
    const tf = atomicTest.input_arguments.terraform
    for (const key in tf) {
        addResources(key, tf[key].name, tf[key].args, tfg)
    }
    const result = tfg.generate();
    return result.tf
}


Glob("../atomics/T*/T*.yaml", function (er, files) {
    files.forEach(path => {
        const dirPath = path.substring(0, path.lastIndexOf("/"))
        const atomicID = dirPath.substring(dirPath.lastIndexOf("/") + 1)
        const doc = yaml.load(fs.readFileSync(path, 'utf8'));
        doc.atomic_tests.forEach((test, index) => {
            try {
                if (!_.isEmpty(test.input_arguments) && !_.isEmpty(test.input_arguments.terraform)) {
                    const tf = generateTerraformFiles(test)
                    const file = `${dirPath}/${atomicID}-${index + 1}.tf`
                    fs.writeFile(file, tf, (error, writtenBytes) => {
                        if (error) {
                            throw error
                        } else {
                            console.log(`File created successfully - ${file}`)
                        }
                    });
                }
            } catch (e) {
                console.log(e)
            }
        })
    })
})
