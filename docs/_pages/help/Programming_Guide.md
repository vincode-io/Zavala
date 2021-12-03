---
layout: single
title: Programming Guide
permalink: /help/Programming_Guide.md/
header:
  overlay_image: /assets/images/phone_and_laptop.png
  overlay_filter: 0.5
---



## Introduction

Zavala includes extensive support for manipulating Outlines using Shortcuts. When possible we have followed the conventions Apple’s default applications. If you can build Shortcuts for those apps, you should be able to do so for Zavala.

## Entity ID

When at all possible we allow you to directly specify the object you are working with, be that an Outline, Row, or something else. There are situations where either an Outline or a Row is a possible parameter. For example when specifying the location that you want to add a Row. This is where the Entity ID comes in.

The Entity ID is a way to uniquely identify an Outline or a Row. You can get the Entity ID for an object by accessing its entityID property. This can then be used to specify either an Outline or Row as required by the Shortcut action you are working with.

## UI Actions

These actions work with the currently active Zavala window.

### Get Current Outline

This will get you the current Outline that is being edited in the foremost Zavala window.

### Get Current Tags

Gets all the Tags if any of the current Outline.

### Show Outline

This will expose the specified Outline in Zavala. This is useful if you have just dynamically created an Outline and want to review it.

## Outline Actions

A set of actions that work directly with Outlines.

### Add Outline

This will create a new Outline.

### Add Outline Tag

Adds a Tag to the specified Outline.

### Edit Outline

Updates the Outline with the specified changes.

### Export

This will export the Outline in the specified format.

### Get Images for Outline

Gets all the Images embedded in the specified Outline.

### Get Outlines

Gets one or more Outlines using the specified criteria. This is often the first step in a Zavala Shortcut.

### Import

This will import the specified file as an Outline. Currently only the OPML format is supported.

### Remove Outline

Deletes the specified Outlines.

### Remove Outline Tag

Removes a Tag from an Outline.

## Row Actions

A set of Actions that work directly with Rows.

### Add Rows

Adds Rows to an Outline.

### Copy Rows

Copy Rows in or between Outlines.

### Edit Rows

Update Row properties.

### Get Rows

Get one or more Rows using criterial.

### Move Rows

Move Rows in or between Outlines.

### Remove Rows

Deletes the specified Rows.