#!/usr/bin/env ts-node
import {TerraformGenerator} from 'terraform-generator';
import * as fs from "fs";
import * as yaml from 'js-yaml';
import Glob from 'glob';
import _ from "lodash"


class Generator {
    constructor(atomicTest) {
        this.tfg = new TerraformGenerator({
            required_version: '>= 0.12'
        });
        this.atomicTest = atomicTest
    }

    addProviders() {
        for (const i of this.atomicTest.supported_platforms) {
            switch (i) {
                case 'iaas:aws':
                    this.tfg.provider('aws');
                    break;
                case 'iaas:azure':
                    this.tfg.provider('azurerm', {'features': {}});
                    break;
                case 'iaas:gcp':
                    this.tfg.provider('google');
                    break;
                default:
                    break;
            }
        }
    }

    getResourceId(idStr) {
        const blocks = this.tfg.getBlocks();
        const [resourceType, resourceName, id] = idStr.split(".")
        for (const i of blocks) {
            if (i.type === resourceType && i.name === resourceName) {
                return i.attr(id)
            }
        }
    }

    addResources(resource, resourceName, resourceArgs) {
        if (!_.isEmpty(resourceArgs)) {
            for (const arg in resourceArgs) {
                const value = resourceArgs[arg];
                if (_.isString(value)) {
                    if (value.startsWith("aws_") || value.startsWith("azurerm_") || value.startsWith("google_")) {
                        resourceArgs[arg] = this.getResourceId(value)
                    }
                }
            }
        }
        this.tfg.resource(resource, resourceName, resourceArgs)
    }

    getTerraformResult() {
        this.addProviders()
        const tf = this.atomicTest.input_arguments.terraform
        for (const key in tf) {
            this.addResources(key, tf[key].name, tf[key].args)
        }
        const result = this.tfg.generate();
        return result.tf
    }
}


Glob("../atomics/T*/T*.yaml", function (er, files) {
    files.forEach(path => {
        const dirPath = path.substring(0, path.lastIndexOf("/"))
        const atomicID = dirPath.substring(dirPath.lastIndexOf("/") + 1)
        const doc = yaml.load(fs.readFileSync(path, 'utf8'));
        doc.atomic_tests.forEach((test, index) => {
            try {
                if (!_.isEmpty(test.input_arguments) && !_.isEmpty(test.input_arguments.terraform)) {
                    const tf = new Generator(test);
                    const file = `${dirPath}/${atomicID}-${index + 1}.tf`
                    fs.writeFile(file, tf.getTerraformResult(), (error, writtenBytes) => {
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
