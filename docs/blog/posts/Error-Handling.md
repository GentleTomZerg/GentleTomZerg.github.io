---
title: Error Handling
authors:
  - GentleTomZerg
date:
  created: 2025-05-24
  updated: 2025-06-21
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

Separation between business logic and error handling is good. However, the process of doing this pushes error detection to the edges of your program. We can define a handler to deal with any aborted computaiton. **BUT** There are some times when you may not want to abort.

<div class="grid" markdown>

```java title="Handle logic in catch"
try {
  MealExpenses expenses = expenseReportDAO.getMeals(employeegetID())
  m_total += expenses.getTotal();
}
catch(MealExpensesNotFound e) {
  m_total += getMealPerDiem();
}
```

```java title="Use Special Case Pattern"
  MealExpenses expenses = expenseReportDAO.getMeals(employeegetID())
  m_total += expenses.getTotal();

  public class PerDiemMealExpenses implements MealExpenses {
    public int getTotal() {
      // return the per diem default
    }
  }
```

</div>

!!! note "Special Case Pattern"

    you create a class or configure an object so that it handles a special case for you. When you do, the client code doesn’t have to deal with exceptional behavior. That behavior is encapsulated in the special case object.

### Don't Return Null

```java title="Many Null checks"
public void registerItem(Item item) {
  if (item != null) {
    ItemRegistry registry = peristentStore.getItemRegistry();
    if (registry != null) {
    Item existing = registry.getItem(item.getID());
      if (existing.getBillingPeriod().hasRetailOwner()) {
        existing.register(item)
      }
    }
  }
}
```

- When return `null`, we are essentially creating work for ourselves and foisting problems upon our callers.
- **If you are tempted to return `null` from a method**, consider throwing an exception or returning a SPECIAL CASE object instead.
- **If you are calling a `null` returnging method from a third-party** API, consider wrapping that method with a method that either throws an excepiton or returns a special case object.

Example:
Java has `Collections.emptyList()`, it returns a predefined immutable list that we can use as a Special Case object, rather than return `null` to the caller who needs a List Object.

### Don't Pass Null

> Returning null from methods is bad, but passing null into methods is worse. Unless you are working with an API which expects you to pass null, you should avoid passing null in your code whenever possible.

<div class="grid" markdown>

```java title="Null pointer Exception"
public class MetricsCalculator  {
  public double xProjection(Point p1, Point p2) {
    return (p2.x – p1.x) * 1.5;
  }
}
```

```java title="Handle Null Args Exception"
public class MetricsCalculator  {
  public double xProjection(Point p1, Point p2) {
    if (p1 == null || p2 == null) {
      throw InvalidArgumentExcepiton("XXX");
    }
    return (p2.x – p1.x) * 1.5;
  }
}
```

```java title="Assert Not Null"
public class MetricsCalculator  {
  public double xProjection(Point p1, Point p2) {
    assert p1 != null : "xxx";
    assert p2 != null : "xxx";
    return (p2.x – p1.x) * 1.5;
  }
}
```

</div>

> In most programming languages there is no good way to deal with a null that is passed by a caller accidentally. Because this is the case, the rational approach is to forbid passing null by default. When you do, you can code with the knowledge that a null in an argument list is an indication of a problem, and end up with far fewer careless mistakes.
