---
title: Error Handling
authors:
  - GentleTomZerg
date:
  created: 2025-05-24
  updated: 2025-05-24
categories:
  - Software Engineering
tags:
  - clean code
---

## Error Handling

> Error handling is important, but if it obscures logic, it’s wrong.

### Use Exceptions Rather than Return Codes

  <div class="grid" markdown>

```java title="Use Return Codes"

public class DeviceController {

    private static final DeviceId DEV1 = DeviceId.DEVICE_1; // Assuming a predefined constant
    private DeviceRecord record;
    private Logger logger = Logger.getLogger(DeviceController.class.getName());

    public void sendShutDown() {
        DeviceHandle handle = getHandle(DEV1);

        // Check the state of the device
        if (handle != DeviceHandle.INVALID) {
            // Save the device status to the record field
            retrieveDeviceRecord(handle);

            // If not suspended, shut down
            if (record.getStatus() != DeviceStatus.DEVICE_SUSPENDED) {
                pauseDevice(handle);
                clearDeviceWorkQueue(handle);
                closeDevice(handle);
            } else {
                logger.log("Device suspended. Unable to shut down");
            }
        } else {
            logger.log("Invalid handle for: " + DEV1.toString());
        }
    }
}

```

```java title="Use Exceptions"

public class DeviceController {

    private static final DeviceId DEV1 = DeviceId.DEVICE_1; // Assumed constant
    private DeviceRecord record;
    private Logger logger = Logger.getLogger(DeviceController.class.getName());

    public void sendShutDown() {
        try {
            tryToShutDown();
        } catch (DeviceShutDownError e) {
            logger.log(e);
        }
    }
  private void tryToShutDown() throws DeviceShutDownError {
      DeviceHandle handle = getHandle(DEV1);
      DeviceRecord record = retrieveDeviceRecord(handle);
      pauseDevice(handle);
      clearDeviceWorkQueue(handle);
      closeDevice(handle);
  }

  private DeviceHandle getHandle(DeviceID id) {
      ...
      throw new DeviceShutDownError("Invalid handle for: " + id.toString());
      ...
  }
}
```

  </div>

  <!-- more -->

### Write Your `Try-Catch-Finally` Statement First

- TDD

### Use Unchecked Exceptions

- Whether checked exceptions are worth their price? -> `Open/Close Principle` violation

> If you throw a checked exception from a method in your code and the catch is three levels above,
> you must declare that exception in the signature of each method between you and the catch.
> This means that a change at a low level of the software can force signature changes on many higher levels.
> The changed modules must be rebuilt and redeployed, even though nothing they care about changed.

- Checked exceptions can sometimes be useful if you are writing a critical library: You must catch them.

### Provide Context with Exceptions

- Each exception that you throw should provide enough context to determine the source and location of an error.
- Mention the operation that failed and the type of the failure.

### Define Exception Classes in Terms of a Caller's Needs

> when we define exception classes in an application, our most important concern should be how they are caught

<div class="grid" markdown>
    
```java title="Poor Exception Classification"
ACMEPort port = new ACMEPort(12);
    
try {
    port.open();
} catch (DeviceResponseException e) {
    reportPortError(e);
    logger.log("Device response exception", e);
} catch (ATM1212UnlockedException e) {
    reportPortError(e);
    logger.log("Unlock exception", e);
} catch (GMXError e) {
    reportPortError(e);
    logger.log("Device response exception");
} finally {
    ...
}
```

```java title="Exception with wrapper"

LocalPort port = new LocalPort(12);

try {
    port.open();
} catch (PortDeviceFailure e) {
    reportError(e);
    logger.log(e.getMessage(), e);
} finally {
    ...
}

public class LocalPort{
  private ACMEPort innerPort;

  public LocalPort(int portNumber) {
    innerPort = new ACMEPort(portNumber);
  }

  public void open() {
    try {
        port.open();
    } catch (DeviceResponseException e) {
        throw new PortDeviceFailure(e);
    } catch (ATM1212UnlockedException e) {
        throw new PortDeviceFailure(e);
    } catch (GMXError e) {
        throw new PortDeviceFailure(e);
    }
}
```

</div>

- Wrapping third-party APIs minimize your dependencies upon it.
- you can choose to move to a different library in the future without much penalty.
- also makes it easier to mock out third-party calls when you are testing your own code.

### Define the Normal Flow
