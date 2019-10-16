# Real World Geometry
Feature lead: Piotr Bialecki (@bialpo)

Status: Incubation

## Introduction
The goal of this feature incubation is to incubate APIs allowing access to real world geometry (abbreviated RWG) like planes and meshes.

Areas explored may include real-world plane and mesh detection, the fine-grained configuration of APIs related to such real-world geometry, the use of and/or interaction of anchors with such real-world geometry, and exposing detailed information about confidence in and quality of such real-world geometry. These explorations may also include the use of such RWG, including using it for hit testing and for occlusion/depth information to allow more realistic rendering of virtual objects in real-world scenes.

The initial focus is on surfacing plane detection API(s). The idea is that in order for some Augmented Reality scenarios to work nicely, developers need to know about surfaces present in the user’s environment (for example to ensure that there is sufficient space to place a virtual object in user’s environment). After surfacing a rudimentary API for plane detection to JavaScript, we will explore the use of the API and RWG, what’s possible in user space, and whether other APIs are necessary.

In addition to just exposing additional functionality, we should also consider allowing app developers to configure it. Example configuration options may include filtering for which types of planes are detected (e.g. only horizontal or vertical planes).

Moreover, it could be beneficial to application developer to be able to retrieve information about the confidence / quality of data returned by RWG APIs.

## Privacy considerations
One of the concerns with exposing real-world understanding information to web applications is the risk that the information will be abused. In order to mitigate that, the User Agent will have to ensure that the user gave the website consent to access RWG data. These topics are explored in the [privacy and security explainer](https://github.com/immersive-web/privacy-and-security/blob/master/EXPLAINER.md#accessing-real-world-data). Proposals in this repo will include mitigations from that repo that are relevant for the covered APIs.
