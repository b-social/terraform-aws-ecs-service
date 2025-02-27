# frozen_string_literal: true

require 'spec_helper'

describe 'task definition' do
  let(:component) do
    var(role: :root, name: 'component')
  end
  let(:deployment_identifier) do
    var(role: :root, name: 'deployment_identifier')
  end
  let(:service_name) do
    var(role: :root, name: 'service_name')
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.service_elb_name =
          output(role: :prerequisites, name: 'load_balancer_name')
      end
    end

    it 'creates an ECS task definition' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_ecs_task_definition')
              .once)
    end

    it 'derives the family from the component, deployment identifier ' \
       'and service name' do
      family = "#{component}-#{service_name}-#{deployment_identifier}"
      expect(@plan)
        .to(include_resource_creation(type: 'aws_ecs_task_definition')
              .with_attribute_value(:family, family))
    end

    it 'uses a network mode of "bridge"' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_ecs_task_definition')
              .with_attribute_value(:network_mode, 'bridge'))
    end

    it 'does not set a PID mode' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_ecs_task_definition')
              .with_attribute_value(:pid_mode, a_nil_value))
    end

    it 'does not set a task role ARN' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_ecs_task_definition')
              .with_attribute_value(:task_role_arn, ''))
    end

    it 'does not configure any volumes' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_ecs_task_definition')
              .with_attribute_value(:volume, a_nil_value))
    end
  end

  describe 'when service_task_network_mode is provided' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.service_elb_name =
          output(role: :prerequisites, name: 'load_balancer_name')
        vars.service_task_network_mode = 'awsvpc'
      end
    end

    it 'uses the provided network mode' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_ecs_task_definition')
              .with_attribute_value(:network_mode, 'awsvpc'))
    end
  end

  describe 'when service_task_pid_mode is provided' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.service_elb_name =
          output(role: :prerequisites, name: 'load_balancer_name')
        vars.service_task_pid_mode = 'host'
      end
    end

    it 'uses the provided PID mode' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_ecs_task_definition')
              .with_attribute_value(:pid_mode, 'host'))
    end
  end

  describe 'when service_role is provided' do
    let(:task_role_arn) do
      output(role: :prerequisites, name: 'task_role_arn')
    end

    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.service_elb_name =
          output(role: :prerequisites, name: 'load_balancer_name')
        vars.service_role =
          output(role: :prerequisites, name: 'task_role_arn')
      end
    end

    it 'uses the provided task role ARN' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_ecs_task_definition')
              .with_attribute_value(:task_role_arn, task_role_arn))
    end
  end

  describe 'when service_volumes is empty' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.service_elb_name =
          output(role: :prerequisites, name: 'load_balancer_name')
        vars.service_volumes = []
      end
    end

    it 'does not configure any volumes' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_ecs_task_definition')
              .with_attribute_value(:volume, a_nil_value))
    end
  end

  describe 'when service_volumes provided' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.service_elb_name =
          output(role: :prerequisites, name: 'load_balancer_name')
        vars.service_volumes = [
          {
            name: 'temporary',
            host_path: '/some/path'
          }
        ]
      end
    end

    it 'configures volumes on the task definition' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_ecs_task_definition')
              .with_attribute_value(
                :volume,
                containing_exactly(
                  a_hash_including(
                    name: 'temporary',
                    host_path: '/some/path'
                  )
                )
              ))
    end
  end
end
